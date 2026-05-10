import Foundation

func formatSeconds(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let m = total / 60
    let s = total % 60
    return String(format: "%02d:%02d", m, s)
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    if minutes == 1 { return "1 min" }
    return "\(minutes) min"
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
}

extension Date {
    static var currentMonthName: String {
        DateFormatter().apply { $0.dateFormat = "MMMM" }.string(from: Date())
    }
}

extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
