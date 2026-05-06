import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var sessionType: String
    var lapIndex: Int

    init(startDate: Date, endDate: Date, duration: TimeInterval,
         sessionType: SessionType, lapIndex: Int) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.sessionType = sessionType.rawValue
        self.lapIndex = lapIndex
    }

    var type: SessionType {
        SessionType(rawValue: sessionType) ?? .focus
    }

    var dayKey: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: endDate)
    }
}
