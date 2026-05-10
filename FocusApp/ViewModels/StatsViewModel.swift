import Foundation

@Observable
final class StatsViewModel {
    var sessions: [FocusSession] = []

    var focusSessions: [FocusSession] {
        sessions.filter { $0.type == .focus }
    }

    var totalSessions: Int { focusSessions.count }

    var totalFocusTime: TimeInterval {
        focusSessions.reduce(0) { $0 + $1.duration }
    }

    var currentStreak: Int {
        StreakService.calculateStreak(from: sessions)
    }

    func weekChartData(offset: Int) -> [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else { return [] }
        return (0..<7).map { dayOffset in
            let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let minutes = focusSessions
                .filter { calendar.isDate($0.endDate, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration / 60 }
            return (day, minutes)
        }
    }

    func monthChartData(offset: Int) -> [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start,
              let targetStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart),
              let monthInterval = calendar.dateInterval(of: .month, for: targetStart) else { return [] }
        let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 30
        return (0..<daysInMonth).map { dayOffset in
            let day = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start)!
            let minutes = focusSessions
                .filter { calendar.isDate($0.endDate, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration / 60 }
            return (day, minutes)
        }
    }

    func weekTitle(offset: Int) -> String {
        let calendar = Calendar.current
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else { return "" }
        let weekNum = calendar.component(.weekOfYear, from: weekStart)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "\(formatter.string(from: weekStart)) · Week \(weekNum)"
    }

    func monthTitle(offset: Int) -> String {
        let calendar = Calendar.current
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start,
              let targetStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: targetStart)
    }

    var todaySessions: Int {
        let calendar = Calendar.current
        return focusSessions.filter { calendar.isDateInToday($0.endDate) }.count
    }

    var todayFocusTime: TimeInterval {
        let calendar = Calendar.current
        return focusSessions
            .filter { calendar.isDateInToday($0.endDate) }
            .reduce(0.0) { $0 + $1.duration }
    }

    var weekSessions: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return focusSessions.filter { $0.endDate >= weekStart }.count
    }

    var weekFocusTime: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return focusSessions
            .filter { $0.endDate >= weekStart }
            .reduce(0.0) { $0 + $1.duration }
    }

    var monthSessions: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return 0 }
        return focusSessions.filter { $0.endDate >= monthStart }.count
    }

    var monthFocusTime: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return 0 }
        return focusSessions
            .filter { $0.endDate >= monthStart }
            .reduce(0.0) { $0 + $1.duration }
    }

    var todayMinutes: Double {
        let calendar = Calendar.current
        return focusSessions
            .filter { calendar.isDateInToday($0.endDate) }
            .reduce(0.0) { $0 + $1.duration / 60 }
    }
}
