import SwiftUI
import SwiftData

struct TimerView: View {
    @Bindable var vm: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    @AppStorage(UserDefaultsKeys.focusDuration)      private var focusDuration: Double = 1500
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreak: Double    = 300
    @AppStorage(UserDefaultsKeys.longBreakDuration)  private var longBreak: Double     = 900
    @AppStorage(UserDefaultsKeys.soundVolume)        private var soundVolume: Double   = 1.0

    var body: some View {
        GeometryReader { geo in
            let ringSize = min(geo.size.width, geo.size.height) * 0.55
            let vSpacing = geo.size.height * 0.04

            ScrollView {
                VStack(spacing: vSpacing) {
                    sessionTypeLabel
                    ringWithTime(size: ringSize)
                    controls(ringSize: ringSize)
                    if case .idle = vm.timerState {
                        idleSettingsPanel
                    }
                }
                .frame(minWidth: geo.size.width)
                .padding(.vertical, vSpacing)
            }
        }
        .background(Color.appBackground)
        .onAppear { vm.setContext(modelContext) }
    }

    // MARK: — Subviews

    private var sessionTypeLabel: some View {
        Text(vm.timerState.sessionType?.label ?? "Ready")
            .font(.headline)
            .foregroundStyle(Color.textSecondary)
    }

    private func ringWithTime(size: CGFloat) -> some View {
        ZStack {
            CircularProgressRing(
                progress: vm.progress,
                ringColor: .ringColor(for: vm.timerState.sessionType ?? .focus)
            )
            .frame(width: size, height: size)

            VStack(spacing: 4) {
                Text(vm.timeString)
                    .font(.system(size: size * 0.22, weight: .thin, design: .monospaced))
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
                icon: "forward.end.fill",
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
            circleButton(icon: "play.fill",    size: size, fgColor: .white, bgColor: .focusRing, action: { vm.start() })
        case .running:
            circleButton(icon: "pause.fill",   size: size, fgColor: .white, bgColor: Color.textPrimary, action: { vm.pause() })
        case .paused:
            circleButton(icon: "play.fill",    size: size, fgColor: .white, bgColor: .focusRing, action: { vm.resume() })
        case .completed:
            circleButton(icon: "arrow.right",  size: size, fgColor: .white, bgColor: .breakRing, action: { vm.next() })
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
            volumeRow
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .padding(.horizontal)
    }

    private var volumeRow: some View {
        HStack(spacing: 10) {
            Image(systemName: soundVolume < 0.01 ? "speaker.slash" : "speaker.wave.2")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)
            Slider(value: $soundVolume, in: 0...1)
                .tint(Color.focusRing)
            Text("\(Int(soundVolume * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: -

private struct DurationRow: View {
    let label: String
    @Binding var seconds: Double
    let range: ClosedRange<Double>

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            Spacer()

            Button {
                seconds = max(seconds - 60, range.lowerBound)
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 30)
                    .focused($isFocused)
                    .onChange(of: text) { _, new in
                        // Strip any non-digit characters immediately
                        let digits = new.filter(\.isNumber)
                        if digits != new { text = digits }
                    }
                    .onSubmit { commit() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commit() }
                    }
                Text("min")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? Color.appBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isFocused ? Color.focusRing.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )

            Button {
                seconds = min(seconds + 60, range.upperBound)
            } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(Color.appBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear { text = minuteString }
        .onChange(of: seconds) { _, _ in
            if !isFocused { text = minuteString }
        }
    }

    private var minuteString: String { String(Int(seconds) / 60) }

    private func commit() {
        guard let minutes = Int(text), minutes > 0 else {
            text = minuteString   // revert if empty or zero
            return
        }
        let clamped = min(max(Double(minutes * 60), range.lowerBound), range.upperBound)
        seconds = clamped
        text = String(Int(clamped) / 60)
    }
}
