import Foundation

enum TranslationDisplayPolicy {
    static func preferredLanguageCode(locale: Locale = .autoupdatingCurrent) -> String? {
        locale.language.languageCode?.identifier
    }

    static func preferredTranslation(
        english: String,
        chinese: String,
        languageCode: String?
    ) -> String {
        guard let normalized = languageCode?.lowercased() else {
            return english
        }

        return normalized.hasPrefix("zh") ? chinese : english
    }
}
