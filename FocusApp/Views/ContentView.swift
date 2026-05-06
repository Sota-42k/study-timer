import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case timer   = "Timer"
    case stats   = "Stats"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timer:    return "timer"
        case .stats:    return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .timer
    @State private var timerVM = TimerViewModel()

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.appSurface)
        } detail: {
            Group {
                switch selection {
                case .timer, .none:
                    TimerView(vm: timerVM)
                case .stats:
                    StatsView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .preferredColorScheme(.light)
        .background(Color.appBackground)
    }
}
