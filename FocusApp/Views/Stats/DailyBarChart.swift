import SwiftUI
import Charts

struct DailyBarChart: View {
    let data: [(date: Date, minutes: Double)]
    let average: Double
    let isMonthly: Bool

    var body: some View {
        Chart {
            ForEach(data, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(Color.focusRing.gradient)
                .cornerRadius(isMonthly ? 2 : 4)
            }
            if isMonthly {
                ForEach(data.filter { Calendar.current.component(.weekday, from: $0.date) == 1 }, id: \.date) { item in
                    RuleMark(x: .value("Week", item.date))
                        .foregroundStyle(Color.appDivider.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            if average > 0 {
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(Color.textSecondary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(Int(average))m")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
            }
        }
        .chartXAxis {
            if isMonthly {
                let sundays = data.map(\.date)
                    .filter { Calendar.current.component(.weekday, from: $0) == 1 }
                AxisMarks(values: sundays) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(Color.textSecondary)
                }
            } else {
                AxisMarks(values: data.map(\.date)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        .foregroundStyle(Color.textSecondary)
                }
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
