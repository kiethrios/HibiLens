import SwiftUI

enum AppAppearancePreference: String, CaseIterable, Equatable, Identifiable {
    case system
    case day
    case dark

    static let storageKey = "app.appearance.preference"
    static let defaultValue: AppAppearancePreference = .system

    var id: String { rawValue }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .day: .light
        case .dark: .dark
        }
    }

    static func resolve(rawValue: String?) -> AppAppearancePreference {
        guard let rawValue,
              let preference = AppAppearancePreference(rawValue: rawValue) else {
            return defaultValue
        }
        return preference
    }
}
