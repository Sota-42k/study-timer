import SwiftUI

struct SettingsView: View {
    @AppStorage(UserDefaultsKeys.focusDuration)      private var focusDuration: Double = 1500
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreak: Double    = 300
    @AppStorage(UserDefaultsKeys.longBreakDuration)  private var longBreak: Double     = 900
    @AppStorage(UserDefaultsKeys.sessionsBeforeLong) private var cycleLength: Int      = 4
    @AppStorage(UserDefaultsKeys.notificationsEnabled) private var notifications: Bool = true

    var body: some View {
        Form {
            Section("Timer Durations") {
                DurationStepper(label: "Focus", seconds: $focusDuration, range: 60...7200, step: 60)
                DurationStepper(label: "Short Break", seconds: $shortBreak, range: 60...3600, step: 60)
                DurationStepper(label: "Long Break", seconds: $longBreak, range: 60...7200, step: 60)
            }
            Section("Cycle") {
                Stepper("Sessions before long break: \(cycleLength)",
                        value: $cycleLength, in: 1...8)
            }
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $notifications)
            }
        }
        .formStyle(.grouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
    }
}

private struct DurationStepper: View {
    let label: String
    @Binding var seconds: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        Stepper(
            "\(label): \(formatDuration(seconds))",
            onIncrement: { seconds = min(seconds + step, range.upperBound) },
            onDecrement: { seconds = max(seconds - step, range.lowerBound) }
        )
    }
}
