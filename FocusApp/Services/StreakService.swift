import Foundation

enum StreakService {
    static func calculateStreak(from sessions: [FocusSession]) -> Int {
        let calendar = Calendar.current
        let focusDays = Set(
            sessions
                .filter { $0.type == .focus }
                .map { calendar.startOfDay(for: $0.endDate) }
        )
        guard !focusDays.isEmpty else { return 0 }

        let sortedDays = focusDays.sorted(by: >)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard sortedDays[0] == today || sortedDays[0] == yesterday else { return 0 }

        var streak = 1
        for i in 1..<sortedDays.count {
            let expected = calendar.date(byAdding: .day, value: -i, to: sortedDays[0])!
            if sortedDays[i] == expected {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
