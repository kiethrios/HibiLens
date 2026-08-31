import SwiftUI

enum AppTypography {
    // MARK: Semantic type roles

    static let japaneseHero = HibiLensTypography.contentHero
    static let japaneseCardTitle = HibiLensTypography.contentCardTitle
    static let japaneseSupport = HibiLensTypography.contentSupport
    static let romajiHelper = HibiLensTypography.transliterationHelper
    static let translationMetadata = HibiLensTypography.metadata
    static let bodyDefinition = HibiLensTypography.definition
    static let actionPrimary = HibiLensTypography.actionPrimary
    static let sectionTitle = HibiLensTypography.sectionTitle
    static let sectionLabel = HibiLensTypography.sectionLabel
    static let metricNumber = HibiLensTypography.metricNumber

    static let displayLarge = HibiLensTypography.displayLarge
    static let displayMedium = HibiLensTypography.displayMedium
    static let displaySmall = HibiLensTypography.displaySmall
    static let displayXLarge = HibiLensTypography.displayXLarge

    static let headlineLarge = HibiLensTypography.headlineLarge
    static let headlineMedium = HibiLensTypography.headlineMedium
    static let headlineSmall = HibiLensTypography.headlineSmall

    static let titleLarge = HibiLensTypography.titleLarge
    static let titleMedium = HibiLensTypography.titleMedium
    static let titleSmall = HibiLensTypography.titleSmall

    static let bodyLarge = HibiLensTypography.bodyLarge
    static let bodyMedium = HibiLensTypography.bodyMedium
    static let bodySmall = HibiLensTypography.bodySmall

    static let labelMedium = HibiLensTypography.labelMedium
    static let labelSmall = HibiLensTypography.labelSmall
    static let labelXSmall = HibiLensTypography.labelXSmall

    // MARK: Tracking

    static let displayTracking = HibiLensTypography.displayTracking
    static let displayHeroTracking = HibiLensTypography.displayHeroTracking
    static let displayMetricTracking = HibiLensTypography.displayMetricTracking
    static let headlineTracking = HibiLensTypography.headlineTracking
    static let labelTracking = HibiLensTypography.labelTracking
    static let eyebrowTracking = HibiLensTypography.eyebrowTracking
    static let sectionLabelTracking = HibiLensTypography.sectionLabelTracking

    // MARK: Japanese line height policy

    static let japaneseLineHeightMinMultiplier = HibiLensTypography.contentLineHeightMinMultiplier
    static let japaneseLineHeightMaxMultiplier = HibiLensTypography.contentLineHeightMaxMultiplier
    static let japaneseLineHeightDefaultMultiplier = HibiLensTypography.contentLineHeightDefaultMultiplier

    static func lineSpacing(
        for fontSize: CGFloat,
        multiplier: CGFloat = japaneseLineHeightDefaultMultiplier
    ) -> CGFloat {
        HibiLensTypography.contentLineSpacing(
            for: fontSize,
            multiplier: multiplier
        )
    }
}

extension View {
    func appJapaneseLineHeight(
        fontSize: CGFloat,
        multiplier: CGFloat = AppTypography.japaneseLineHeightDefaultMultiplier
    ) -> some View {
        lineSpacing(AppTypography.lineSpacing(for: fontSize, multiplier: multiplier))
    }
}
