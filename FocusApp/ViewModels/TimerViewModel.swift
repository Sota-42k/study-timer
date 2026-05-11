import SwiftUI
import SwiftData

enum TimerState: Equatable {
    case idle
    case running(SessionType)
    case paused(SessionType)
    case completed(SessionType)

    static func == (lhs: TimerState, rhs: TimerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.running(let a), .running(let b)): return a == b
        case (.paused(let a), .paused(let b)): return a == b
        case (.completed(let a), .completed(let b)): return a == b
        default: return false
        }
    }

    var sessionType: SessionType? {
        switch self {
        case .running(let t), .paused(let t), .completed(let t): return t
        case .idle: return nil
        }
    }
}

@Observable
final class TimerViewModel {
    var timerState: TimerState = .idle
    var secondsRemaining: TimeInterval = 0
    var totalSeconds: TimeInterval = 0
    var currentLapIndex: Int = 0
    var completedFocusInCycle: Int = 0
    var completedCycles: Int = 0
    var laps: [FocusSession] = []

    private var sessionStartDate: Date?
    private var timerTask: Timer?
    private var modelContext: ModelContext?

    func setContext(_ ctx: ModelContext) {
        self.modelContext = ctx
        fetchLaps()
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (secondsRemaining / totalSeconds)
    }

    var timeString: String {
        formatSeconds(secondsRemaining)
    }

    var currentPhaseIndex: Int? {
        guard timerState != .idle else { return nil }

        let laps = max(UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionsBeforeLong), 1)

        // After long break completes, completedCycles is already incremented and
        // completedFocusInCycle is reset — point back to the last segment of the previous cycle.
        if timerState == .completed(.longBreak) {
            guard completedCycles > 0 else { return nil }
            return (completedCycles - 1) * 2 * laps + (2 * laps - 1)
        }

        let cycleBase = completedCycles * 2 * laps

        switch timerState.sessionType {
        case .focus:
            if case .completed = timerState {
                // completedFocusInCycle already incremented — stay on the focus segment
                return cycleBase + 2 * max(completedFocusInCycle - 1, 0)
            }
            return cycleBase + 2 * completedFocusInCycle
        case .shortBreak, .longBreak:
            // completedFocusInCycle == number of focus sessions done in this cycle
            return cycleBase + 2 * completedFocusInCycle - 1
        case nil:
            return nil
        }
    }

    var progressLabel: String {
        guard let sessionType = timerState.sessionType else { return "" }

        let lapsPerCycle = {
            let v = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionsBeforeLong)
            return v > 0 ? v : 4
        }()
        let totalCycles = {
            let v = UserDefaults.standard.integer(forKey: UserDefaultsKeys.cycleCount)
            return v > 0 ? v : 1
        }()

        if sessionType == .longBreak {
            let cycleNum = (timerState == .completed(.longBreak)) ? completedCycles : completedCycles + 1
            return "Cycle \(cycleNum) / \(totalCycles)"
        }

        let lapNum: Int = {
            if case .running(.focus) = timerState { return completedFocusInCycle + 1 }
            return completedFocusInCycle
        }()

        return "Lap \(lapNum) / \(lapsPerCycle) · Cycle \(completedCycles + 1) / \(totalCycles)"
    }

    // MARK: — Actions

    func start() {
        let duration = durationForType(.focus)
        totalSeconds = duration
        secondsRemaining = duration
        sessionStartDate = Date()
        timerState = .running(.focus)
        startTimer()
    }

    func pause() {
        guard case .running(let type) = timerState else { return }
        timerTask?.invalidate()
        timerTask = nil
        timerState = .paused(type)
    }

    func resume() {
        guard case .paused(let type) = timerState else { return }
        timerState = .running(type)
        startTimer()
    }

    func reset() {
        timerTask?.invalidate()
        timerTask = nil
        timerState = .idle
        secondsRemaining = 0
        totalSeconds = 0
        sessionStartDate = nil
        completedFocusInCycle = 0
        completedCycles = 0
    }

    func skip() {
        let type: SessionType
        switch timerState {
        case .running(let t): type = t
        case .paused(let t):  type = t
        default: return
        }
        timerTask?.invalidate()
        timerTask = nil
        if type == .focus {
            completedFocusInCycle += 1
        } else if type == .longBreak {
            completedCycles += 1
            completedFocusInCycle = 0
        }
        timerState = .completed(type)
        next()
    }

    func next() {
        guard case .completed(let type) = timerState else { return }

        if type == .longBreak {
            let target = UserDefaults.standard.integer(forKey: UserDefaultsKeys.cycleCount)
            let effective = target > 0 ? target : 1
            if completedCycles >= effective {
                reset()
                return
            }
        }

        var nextType = determineNextType(after: type)
        var duration = durationForType(nextType)

        // Skip 0-duration breaks: apply their side effects and jump straight to focus.
        if duration == 0 && nextType != .focus {
            if nextType == .longBreak {
                completedCycles += 1
                completedFocusInCycle = 0
                let target = UserDefaults.standard.integer(forKey: UserDefaultsKeys.cycleCount)
                let effective = target > 0 ? target : 1
                if completedCycles >= effective {
                    reset()
                    return
                }
            }
            nextType = .focus
            duration = durationForType(.focus)
        }

        totalSeconds = duration
        secondsRemaining = duration
        sessionStartDate = Date()
        timerState = .running(nextType)
        startTimer()
    }

    // MARK: — Private

    private func startTimer() {
        timerTask?.invalidate()
        timerTask = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.handleCompletion()
            }
        }
        RunLoop.main.add(timerTask!, forMode: .common)
    }

    private func handleCompletion() {
        timerTask?.invalidate()
        timerTask = nil

        guard case .running(let type) = timerState,
              let start = sessionStartDate else { return }

        if type == .focus {
            let session = FocusSession(
                startDate: start,
                endDate: Date(),
                duration: totalSeconds,
                sessionType: .focus,
                lapIndex: currentLapIndex
            )
            modelContext?.insert(session)
            laps.insert(session, at: 0)
            currentLapIndex += 1
            completedFocusInCycle += 1
        } else if type == .longBreak {
            completedCycles += 1
            completedFocusInCycle = 0
        }

        timerState = .completed(type)
        NotificationService.shared.fireCompletionNotification(for: type)

        // Auto-advance after every session; next() handles cycle-count exhaustion.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.next()
        }
    }

    private func determineNextType(after type: SessionType) -> SessionType {
        switch type {
        case .focus:
            let cycleLen = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionsBeforeLong)
            let effectiveCycle = cycleLen > 0 ? cycleLen : 4
            return (completedFocusInCycle % effectiveCycle == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    private func durationForType(_ type: SessionType) -> TimeInterval {
        let ud = UserDefaults.standard
        switch type {
        case .focus:
            guard ud.object(forKey: UserDefaultsKeys.focusDuration) != nil else { return 1500 }
            return max(ud.double(forKey: UserDefaultsKeys.focusDuration), 60)
        case .shortBreak:
            return ud.object(forKey: UserDefaultsKeys.shortBreakDuration) != nil
                ? ud.double(forKey: UserDefaultsKeys.shortBreakDuration)
                : 300
        case .longBreak:
            return ud.object(forKey: UserDefaultsKeys.longBreakDuration) != nil
                ? ud.double(forKey: UserDefaultsKeys.longBreakDuration)
                : 1800
        }
    }

    private func fetchLaps() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.sessionType == "focus" },
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        laps = (try? ctx.fetch(descriptor)) ?? []
        currentLapIndex = laps.count
    }
}
