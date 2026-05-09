import SwiftUI
import SwiftData

struct TimerView: View {
    @Bindable var vm: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    @AppStorage(UserDefaultsKeys.focusDuration)      private var focusDuration: Double = 1500
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreak: Double    = 300
    @AppStorage(UserDefaultsKeys.longBreakDuration)  private var longBreak: Double     = 900
    @AppStorage(UserDefaultsKeys.sessionsBeforeLong) private var cycleLength: Int      = 4
    @AppStorage(UserDefaultsKeys.cycleCount)          private var cycleCount: Int       = 1

    var body: some View {
        GeometryReader { geo in
            // Settings panel is compact (~120pt), ring gets the remaining space.
            // Clamp to ≥80 so SF Symbol font size is never 0 on the first layout pass.
            let ringSize = max(min(geo.size.width * 0.52, geo.size.height * 0.46), 80)
            let gap      = geo.size.height * 0.025

            VStack(spacing: 0) {
                CycleProgressBar(vm: vm)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)

                sessionTypeLabel
                    .padding(.bottom, gap)

                ringWithTime(size: ringSize)

                controls(ringSize: ringSize)
                    .padding(.top, gap)

                Spacer(minLength: 0)

                if case .idle = vm.timerState {
                    idleSettingsPanel
                        .padding(.bottom, 16)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            // Clicking any blank area resigns the active text field.
            Color.appBackground.onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        )
        .onAppear { vm.setContext(modelContext) }
    }

    // MARK: — Subviews

    private var sessionTypeLabel: some View {
        VStack(spacing: 2) {
            Text(vm.timerState.sessionType?.label ?? "Ready")
                .font(.headline)
                .foregroundStyle(Color.textSecondary)
            if !vm.progressLabel.isEmpty {
                Text(vm.progressLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary.opacity(0.65))
            }
        }
    }

    private func ringWithTime(size: CGFloat) -> some View {
        ZStack {
            CircularProgressRing(
                progress: vm.progress,
                ringColor: .ringColor(for: vm.timerState.sessionType ?? .focus)
            )
            .animation(
                { if case .running = vm.timerState { return .linear(duration: 1) }; return nil }(),
                value: vm.progress
            )
            .frame(width: size, height: size)

            VStack(spacing: 4) {
                // Show the current focus duration when idle so changes reflect immediately
                let displayTime: String = {
                    if case .idle = vm.timerState { return formatSeconds(focusDuration) }
                    return vm.timeString
                }()

                Text(displayTime)
                    .font(.system(size: size * 0.27, weight: .thin, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)

                if case .idle = vm.timerState {
                    Text("Press start")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func controls(ringSize: CGFloat) -> some View {
        let secondary = ringSize * 0.20
        let primary   = ringSize * 0.28

        return HStack(spacing: ringSize * 0.09) {
            circleButton(
                icon: "arrow.counterclockwise",
                size: secondary,
                fgColor: Color.textSecondary,
                bgColor: Color.appSurface,
                action: { vm.reset() }
            )
            .disabled(vm.timerState == .idle)

            primaryButton(size: primary)

            circleButton(
                icon: "forward.fill",
                size: secondary,
                fgColor: Color.textSecondary,
                bgColor: Color.appSurface,
                action: { vm.skip() }
            )
            .opacity(vm.timerState == .idle ? 0 : 1)
            .disabled(vm.timerState == .idle)
        }
    }

    @ViewBuilder
    private func primaryButton(size: CGFloat) -> some View {
        switch vm.timerState {
        case .idle:
            circleButton(icon: "play.fill",   size: size, fgColor: .white, bgColor: .focusRing,         action: { vm.start() })
        case .running:
            circleButton(icon: "pause.fill",  size: size, fgColor: .white, bgColor: Color.textPrimary,  action: { vm.pause() })
        case .paused:
            circleButton(icon: "play.fill",   size: size, fgColor: .white, bgColor: .focusRing,         action: { vm.resume() })
        case .completed(let type):
            circleButton(icon: "arrow.right", size: size, fgColor: .white, bgColor: .ringColor(for: type), action: { vm.next() })
        }
    }

    private func circleButton(icon: String, size: CGFloat, fgColor: Color, bgColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.35))
                .foregroundStyle(fgColor)
                .frame(width: size, height: size)
                .background(bgColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }

    // MARK: — Idle settings panel

    private var idleSettingsPanel: some View {
        VStack(spacing: 0) {
            DurationRow(label: "Focus",       seconds: $focusDuration, range: 60...7200)
            Divider().opacity(0.4).padding(.leading, 16)
            DurationRow(label: "Short Break", seconds: $shortBreak,    range: 60...3600)
            Divider().opacity(0.4).padding(.leading, 16)
            DurationRow(label: "Long Break",  seconds: $longBreak,     range: 60...7200)
            Divider().opacity(0.4).padding(.leading, 16)
            CountRow(label: "Laps per cycle", value: $cycleLength, range: 1...8)
            Divider().opacity(0.4).padding(.leading, 16)
            CountRow(label: "Cycles", value: $cycleCount, range: 1...8)
            Divider().opacity(0.4).padding(.leading, 16)
            VolumeRow()
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .frame(maxWidth: 360)
        .padding(.horizontal)
    }
}

// MARK: -

struct DurationRow: View {
    let label: String
    @Binding var seconds: Double
    let range: ClosedRange<Double>

    @State private var text: String = ""
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textPrimary)
            Spacer()

            Button {
                let v = max(seconds - 60, range.lowerBound)
                seconds = v
                text = mins(v)
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                // onEditingChanged maps directly to NSTextField's begin/end editing
                // delegate callbacks — far more reliable than @FocusState on macOS.
                TextField("", text: $text, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing { commit() }
                })
                .textFieldStyle(.plain)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(width: 30)
                .onChange(of: text) { _, new in
                    let digits = new.filter(\.isNumber)
                    if digits != new { text = digits }
                }
                .onSubmit {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
                .onExitCommand {
                    text = mins(seconds)
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }

                Text("min")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isEditing ? Color.appBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isEditing ? Color.focusRing.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )

            Button {
                let v = min(seconds + 60, range.upperBound)
                seconds = v
                text = mins(v)
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .onAppear { text = mins(seconds) }
        .onChange(of: seconds) { _, v in
            if !isEditing { text = mins(v) }
        }
    }

    private func mins(_ s: Double) -> String { String(Int(s) / 60) }

    private func commit() {
        guard let m = Int(text), m > 0 else {
            text = mins(seconds)
            return
        }
        let clamped = min(max(Double(m * 60), range.lowerBound), range.upperBound)
        seconds = clamped
        text = mins(clamped)
    }
}

// MARK: -

struct CountRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var text = ""
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textPrimary)
            Spacer()

            Button {
                let v = max(value - 1, range.lowerBound)
                value = v; text = "\(v)"
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                TextField("", text: $text, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing { commit() }
                })
                .textFieldStyle(.plain)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(width: 22)
                .onChange(of: text) { _, new in
                    let d = new.filter(\.isNumber)
                    if d != new { text = d }
                }
                .onSubmit { NSApp.keyWindow?.makeFirstResponder(nil) }
                .onExitCommand { text = "\(value)"; NSApp.keyWindow?.makeFirstResponder(nil) }

                Text("sessions")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isEditing ? Color.appBackground : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isEditing ? Color.focusRing.opacity(0.5) : Color.clear, lineWidth: 1))
            )

            Button {
                let v = min(value + 1, range.upperBound)
                value = v; text = "\(v)"
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 22, height: 22)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .onAppear { text = "\(value)" }
        .onChange(of: value) { _, v in if !isEditing { text = "\(v)" } }
    }

    private func commit() {
        guard let v = Int(text), range.contains(v) else { text = "\(value)"; return }
        value = v
    }
}

// MARK: -

struct VolumeRow: View {
    @AppStorage(UserDefaultsKeys.soundVolume) private var volume: Double = 1.0
    @State private var text = ""
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: volume < 0.01 ? "speaker.slash" : "speaker.wave.2")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 16)

            Slider(value: $volume, in: 0...1)
                .tint(Color.focusRing)
                .onChange(of: volume) { _, v in
                    if !isEditing { text = pct(v) }
                }

            HStack(spacing: 1) {
                TextField("", text: $text, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing { commit() }
                })
                .textFieldStyle(.plain)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(width: 24)
                .onChange(of: text) { _, new in
                    let d = new.filter(\.isNumber)
                    if d != new { text = d }
                }
                .onSubmit { NSApp.keyWindow?.makeFirstResponder(nil) }
                .onExitCommand { text = pct(volume); NSApp.keyWindow?.makeFirstResponder(nil) }

                Text("%")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isEditing ? Color.appBackground : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isEditing ? Color.focusRing.opacity(0.5) : Color.clear, lineWidth: 1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .onAppear { text = pct(volume) }
    }

    private func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))" }

    private func commit() {
        guard let p = Int(text) else { text = pct(volume); return }
        let clamped = min(max(Double(p) / 100.0, 0.0), 1.0)
        volume = clamped
        text = pct(clamped)
    }
}
