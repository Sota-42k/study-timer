import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @State private var statsVM = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                chartSection
                summarySection
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .onChange(of: sessions) { _, newValue in
            statsVM.sessions = newValue
        }
        .onAppear { statsVM.sessions = sessions }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, 4)

            DailyBarChart(data: statsVM.last7DaysData)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var summarySection: some View {
        VStack(spacing: 0) {
            StatSummaryRow(
                label: "Current streak",
                value: "\(statsVM.currentStreak) day\(statsVM.currentStreak == 1 ? "" : "s")",
                icon: "flame.fill"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "Total sessions",
                value: "\(statsVM.totalSessions)",
                icon: "checkmark.circle.fill"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "Total focus time",
                value: formatDuration(statsVM.totalFocusTime),
                icon: "clock.fill"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "Today",
                value: "\(Int(statsVM.todayMinutes)) min",
                icon: "sun.max.fill"
            )
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
