import SwiftUI

extension Color {
    static let appBackground  = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let appSurface     = Color.white
    static let focusRing      = Color(red: 0.22, green: 0.68, blue: 0.44)
    static let breakRing      = Color(red: 0.22, green: 0.50, blue: 0.88)
    static let longBreakRing  = Color(red: 0.12, green: 0.30, blue: 0.62)
    static let textPrimary    = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let textSecondary  = Color(red: 0.50, green: 0.50, blue: 0.54)
    static let appDivider     = Color.black.opacity(0.07)
}

extension Color {
    static func ringColor(for type: SessionType) -> Color {
        switch type {
        case .focus:      return .focusRing
        case .shortBreak: return .breakRing
        case .longBreak:  return .longBreakRing
        }
    }
}
