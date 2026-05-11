import SwiftUI

struct SettingsView: View {
    @AppStorage(UserDefaultsKeys.focusDuration)        private var focusDuration: Double = 1500
    @AppStorage(UserDefaultsKeys.shortBreakDuration)   private var shortBreak: Double    = 300
    @AppStorage(UserDefaultsKeys.longBreakDuration)    private var longBreak: Double     = 1800
    @AppStorage(UserDefaultsKeys.sessionsBeforeLong)   private var cycleLength: Int      = 4
    @AppStorage(UserDefaultsKeys.cycleCount)            private var cycleCount: Int       = 1
    @AppStorage(UserDefaultsKeys.notificationsEnabled) private var notifications: Bool   = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                card {
                    sectionLabel("Timer Durations")
                    DurationRow(label: "Focus",       seconds: $focusDuration, range: 60...10800)
                    Divider().opacity(0.4).padding(.leading, 16)
                    DurationRow(label: "Short Break", seconds: $shortBreak,    range: 0...3600)
                    Divider().opacity(0.4).padding(.leading, 16)
                    DurationRow(label: "Long Break",  seconds: $longBreak,     range: 0...10800)
                }

                card {
                    sectionLabel("Cycle")
                    CountRow(label: "Laps per cycle", value: $cycleLength, range: 1...8)
                    Divider().opacity(0.4).padding(.leading, 16)
                    CountRow(label: "Cycles", value: $cycleCount, range: 1...8)
                }

                card {
                    sectionLabel("Sound")
                    VolumeRow()
                }

                card {
                    sectionLabel("Notifications")
                    HStack {
                        Text("Enable notifications")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Toggle("", isOn: $notifications)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .padding(20)
        }
        .background(
            Color.appBackground.onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}
