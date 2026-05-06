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
    }

    func skip() {
        guard case .running(let type) = timerState else { return }
        timerTask?.invalidate()
        timerTask = nil
        timerState = .completed(type)
        // No save on skip
    }

    func next() {
        guard case .completed(let type) = timerState else { return }
        let nextType = determineNextType(after: type)
        let duration = durationForType(nextType)
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
        }

        timerState = .completed(type)
        NotificationService.shared.fireCompletionNotification(for: type)

        // Auto-advance to the next session after a brief pause.
        // Stop after the long break — that marks the end of one full cycle.
        if type != .longBreak {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.next()
            }
        }
    }

    private func determineNextType(after type: SessionType) -> SessionType {
        switch type {
        case .focus:
            let cycleLen = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionsBeforeLong)
            let effectiveCycle = cycleLen > 0 ? cycleLen : 4
            return (completedFocusInCycle % effectiveCycle == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            if type == .longBreak { completedFocusInCycle = 0 }
            return .focus
        }
    }

    private func durationForType(_ type: SessionType) -> TimeInterval {
        let ud = UserDefaults.standard
        switch type {
        case .focus:
            let v = ud.double(forKey: UserDefaultsKeys.focusDuration)
            return v > 0 ? v : 1500
        case .shortBreak:
            let v = ud.double(forKey: UserDefaultsKeys.shortBreakDuration)
            return v > 0 ? v : 300
        case .longBreak:
            let v = ud.double(forKey: UserDefaultsKeys.longBreakDuration)
            return v > 0 ? v : 900
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
