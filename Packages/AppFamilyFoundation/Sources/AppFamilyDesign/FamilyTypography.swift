import SwiftUI

/// Stage 1 typography compatibility primitives shared by the app family.
///
/// The first role family, from `contentHero` through `metricNumber`, expresses
/// content-presentation needs. The second, from `displayLarge` through
/// `labelXSmall`, expresses generic interface hierarchy.
///
/// Exact fixed point sizes are intentional for Stage 1 compatibility. These
/// roles do not introduce new Dynamic Type scaling; scaling policy remains
/// host/app-owned until a future family contract defines it.
public enum FamilyTypography {
    public static let contentHero = Font.system(size: 50, weight: .medium, design: .default)
    public static let contentCardTitle = Font.system(size: 28, weight: .medium, design: .default)
    public static let contentSupport = Font.system(size: 17, weight: .medium, design: .default)
    public static let transliterationHelper = Font.system(size: 13, weight: .medium, design: .default)
    public static let metadata = Font.system(size: 12, weight: .medium, design: .default)
    public static let definition = Font.system(size: 16, weight: .regular, design: .default)
    public static let actionPrimary = Font.system(size: 17, weight: .semibold, design: .default)
    public static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .default)
    public static let sectionLabel = Font.system(size: 12, weight: .semibold, design: .default)
    public static let metricNumber = Font.system(size: 42, weight: .medium, design: .default)

    public static let displayLarge = Font.system(size: 44, weight: .regular)
    public static let displayMedium = Font.system(size: 36, weight: .regular)
    public static let displaySmall = Font.system(size: 30, weight: .regular)
    public static let displayXLarge = Font.system(size: 60, weight: .heavy)
    public static let headlineLarge = Font.system(size: 24, weight: .regular)
    public static let headlineMedium = Font.system(size: 20, weight: .regular)
    public static let headlineSmall = Font.system(size: 18, weight: .regular)
    public static let titleLarge = Font.system(size: 18, weight: .regular)
    public static let titleMedium = Font.system(size: 16, weight: .medium)
    public static let titleSmall = Font.system(size: 14, weight: .medium)
    public static let bodyLarge = Font.system(size: 16, weight: .regular)
    public static let bodyMedium = Font.system(size: 14, weight: .regular)
    public static let bodySmall = Font.system(size: 12, weight: .regular)
    public static let labelMedium = Font.system(size: 14, weight: .regular)
    public static let labelSmall = Font.system(size: 12, weight: .regular)
    public static let labelXSmall = Font.system(size: 10, weight: .regular)

    public static let displayTracking: CGFloat = 0
    public static let displayHeroTracking: CGFloat = 0
    public static let displayMetricTracking: CGFloat = 0
    public static let headlineTracking: CGFloat = 0
    public static let labelTracking: CGFloat = 0.8
    public static let eyebrowTracking: CGFloat = 0.9
    public static let sectionLabelTracking: CGFloat = 1.1

    public static let contentLineHeightMinMultiplier: CGFloat = 1.5
    public static let contentLineHeightMaxMultiplier: CGFloat = 1.8
    public static let contentLineHeightDefaultMultiplier: CGFloat = 1.6

    /// Returns the extra spacing needed to realize a clamped content line height.
    ///
    /// - Precondition: `fontSize` is finite and nonnegative, and `multiplier`
    ///   is finite.
    /// - Parameters:
    ///   - fontSize: The fixed point size of the content font.
    ///   - multiplier: The requested line-height multiplier.
    /// - Returns: Nonnegative extra spacing using the approved multiplier range.
    public static func contentLineSpacing(
        for fontSize: CGFloat,
        multiplier: CGFloat = contentLineHeightDefaultMultiplier
    ) -> CGFloat {
        let clamped = min(
            max(multiplier, contentLineHeightMinMultiplier),
            contentLineHeightMaxMultiplier
        )
        return max((fontSize * clamped) - fontSize, 0)
    }
}
