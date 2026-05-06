import SwiftUI
import Charts

struct DailyBarChart: View {
    let data: [(date: Date, minutes: Double)]

    var body: some View {
        Chart(data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(Color.focusRing.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(dash: [4]))
                    .foregroundStyle(Color.appDivider)
                AxisValueLabel()
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .frame(height: 180)
    }
}
