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

    var last7DaysData: [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> (Date, Double) in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let minutes = focusSessions
                .filter { calendar.isDate($0.endDate, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration / 60 }
            return (day, minutes)
        }
    }

    var last30DaysData: [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<30).reversed().map { offset -> (Date, Double) in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let minutes = focusSessions
                .filter { calendar.isDate($0.endDate, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration / 60 }
            return (day, minutes)
        }
    }

    var weeklyAverage: Double {
        let values = last7DaysData.map { $0.minutes }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    var monthlyAverage: Double {
        let values = last30DaysData.map { $0.minutes }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    var todayMinutes: Double {
        let calendar = Calendar.current
        return focusSessions
            .filter { calendar.isDateInToday($0.endDate) }
            .reduce(0.0) { $0 + $1.duration / 60 }
    }
}
