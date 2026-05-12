import SwiftUI
import Charts

struct DailyBarChart: View {
    let data: [(date: Date, minutes: Double)]
    let average: Double
    let isMonthly: Bool
    let isCurrentPeriod: Bool

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var showToday: Bool {
        isCurrentPeriod && data.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
    }

    private var todayDateInData: Date? {
        data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.date
    }

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
                AxisMarks(values: sundays) { value in
                    if let date = value.as(Date.self),
                       showToday,
                       Calendar.current.isDate(date, inSameDayAs: today) {
                        AxisValueLabel {
                            VStack(spacing: 2) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .foregroundStyle(Color.textSecondary)
                                todayIndicator
                            }
                        }
                    } else {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                // Today indicator for monthly view when today is not a Sunday
                if showToday,
                   let td = todayDateInData,
                   Calendar.current.component(.weekday, from: td) != 1 {
                    AxisMarks(values: [Calendar.current.date(byAdding: .hour, value: 12, to: td) ?? td]) { _ in
                        AxisValueLabel { todayIndicator }
                    }
                }
            } else {
                AxisMarks(values: data.map(\.date)) { value in
                    if showToday,
                       let date = value.as(Date.self),
                       Calendar.current.isDate(date, inSameDayAs: today) {
                        AxisValueLabel(centered: true) {
                            VStack(spacing: 2) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .foregroundStyle(Color.textSecondary)
                                todayIndicator
                            }
                        }
                    } else {
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            .foregroundStyle(Color.textSecondary)
                    }
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

    private var todayIndicator: some View {
        VStack(spacing: 2) {
            UpwardTriangle()
                .fill(Color.black)
                .frame(width: 7, height: 5.25)
            Text("today")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.black)
        }
    }
}

private struct UpwardTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
