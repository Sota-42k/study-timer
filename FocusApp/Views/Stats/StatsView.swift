import SwiftUI
import SwiftData

enum ChartRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @State private var statsVM = StatsViewModel()
    @State private var chartRange: ChartRange = .week
    @Namespace private var rangeToggleNS

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
            HStack {
                Text(chartRange == .week ? "Last 7 Days" : "Last 30 Days")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.leading, 4)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                chartRange = range
                            }
                        } label: {
                            Text(range.rawValue)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(chartRange == range ? Color.white : Color.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background {
                                    if chartRange == range {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.55))
                                            .matchedGeometryEffect(id: "rangeIndicator", in: rangeToggleNS)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            DailyBarChart(
                data: chartRange == .week ? statsVM.last7DaysData : statsVM.last30DaysData,
                average: chartRange == .week ? statsVM.weeklyAverage : statsVM.monthlyAverage,
                isMonthly: chartRange == .month
            )
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
