import SwiftUI
import SwiftData
import AppKit

enum ChartRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @State private var statsVM = StatsViewModel()
    @State private var chartRange: ChartRange = .week
    @State private var weekOffset: Int = 0
    @State private var monthOffset: Int = 0
    @Namespace private var rangeToggleNS

    private var isAtCurrentPeriod: Bool {
        chartRange == .week ? weekOffset == 0 : monthOffset == 0
    }

    private func stepSmall(_ direction: Int) {
        if chartRange == .week {
            weekOffset = min(0, weekOffset + direction)
        } else {
            monthOffset = min(0, monthOffset + direction)
        }
    }

    private func stepLarge(_ direction: Int) {
        if chartRange == .week {
            let calendar = Calendar.current
            guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
                  let displayedWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart),
                  let targetDate = calendar.date(byAdding: .month, value: direction, to: displayedWeekStart),
                  let targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start else { return }
            let days = calendar.dateComponents([.day], from: currentWeekStart, to: targetWeekStart).day ?? 0
            weekOffset = min(0, days / 7)
        } else {
            monthOffset = min(0, monthOffset + direction * 12)
        }
    }

    private var currentChartData: [(date: Date, minutes: Double)] {
        chartRange == .week
            ? statsVM.weekChartData(offset: weekOffset)
            : statsVM.monthChartData(offset: monthOffset)
    }

    private var currentChartAverage: Double {
        let data = currentChartData
        guard !data.isEmpty else { return 0 }
        return data.reduce(0.0) { $0 + $1.minutes } / Double(data.count)
    }

    private var chartTitle: String {
        chartRange == .week
            ? statsVM.weekTitle(offset: weekOffset)
            : statsVM.monthTitle(offset: monthOffset)
    }

    var body: some View {
        VStack(spacing: 20) {
            chartSection
            summarySection
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
        .onChange(of: sessions) { _, newValue in
            statsVM.sessions = newValue
        }
        .onAppear { statsVM.sessions = sessions }
    }

    private var chartNavHeader: some View {
        HStack(spacing: 4) {
            navButton("chevron.left.2") { stepLarge(-1) }
            navButton("chevron.left") { stepSmall(-1) }

            Text(chartTitle)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(minWidth: 200, alignment: .center)

            navButton("chevron.right", disabled: isAtCurrentPeriod) { stepSmall(1) }
            navButton("chevron.right.2", disabled: isAtCurrentPeriod) { stepLarge(1) }

            Spacer()

            rangeToggle
        }
    }

    private func navButton(_ icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(disabled ? Color.textSecondary.opacity(0.25) : Color.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var rangeToggle: some View {
        HStack(spacing: 0) {
            ForEach(ChartRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        chartRange = range
                        weekOffset = 0
                        monthOffset = 0
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

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartNavHeader

            DailyBarChart(
                data: currentChartData,
                average: currentChartAverage,
                isMonthly: chartRange == .month
            )
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            ScrollWheelCapture { step in
                withAnimation(.easeInOut(duration: 0.2)) { stepSmall(step) }
            }
        )
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
                label: "Today",
                value: "\(statsVM.todaySessions) / \(formatDuration(statsVM.todayFocusTime))",
                icon: "sun.max.fill"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "This week (Sun–Sat)",
                value: "\(statsVM.weekSessions) / \(formatDuration(statsVM.weekFocusTime))",
                icon: "calendar"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "This month (\(Date.currentMonthName))",
                value: "\(statsVM.monthSessions) / \(formatDuration(statsVM.monthFocusTime))",
                icon: "calendar.badge.clock"
            )
            Divider().opacity(0.15).padding(.leading, 56)
            StatSummaryRow(
                label: "Total",
                value: "\(statsVM.totalSessions) / \(formatDuration(statsVM.totalFocusTime))",
                icon: "checkmark.circle.fill"
            )
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Scroll wheel capture

struct ScrollWheelCapture: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> ScrollCaptureNSView {
        ScrollCaptureNSView(onStep: onStep)
    }

    func updateNSView(_ nsView: ScrollCaptureNSView, context: Context) {
        nsView.onStep = onStep
    }
}

class ScrollCaptureNSView: NSView {
    var onStep: ((Int) -> Void)?
    private var eventMonitor: Any?
    private var accumulated: CGFloat = 0
    private let threshold: CGFloat = 30

    init(onStep: @escaping (Int) -> Void) {
        self.onStep = onStep
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        guard window != nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    deinit {
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        let mouseInWindow = event.locationInWindow
        let selfInWindow = convert(bounds, to: nil)
        guard selfInWindow.contains(mouseInWindow) else { return event }

        guard event.momentumPhase == [] else { return nil }

        if !event.hasPreciseScrollingDeltas {
            // Mouse wheel: each detent triggers one step
            let delta = abs(event.deltaX) >= abs(event.deltaY) ? event.deltaX : -event.deltaY
            if delta != 0 { onStep?(delta > 0 ? 1 : -1) }
            return nil
        }

        // Trackpad: accumulate until threshold to avoid accidental steps
        if event.phase == .began { accumulated = 0 }
        let delta = abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY)
            ? event.scrollingDeltaX
            : -event.scrollingDeltaY
        accumulated += delta
        if abs(accumulated) >= threshold {
            onStep?(accumulated > 0 ? 1 : -1)
            accumulated = 0
        }
        return nil
    }
}
