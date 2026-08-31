import SwiftUI
import UIKit

struct VisualColorToken: Equatable {
    let foundationToken: HibiLensVisualColorToken

    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        let foundationToken = HibiLensVisualColorToken(
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
        self.init(foundationToken: foundationToken)
    }

    init(foundationToken: HibiLensVisualColorToken) {
        self.foundationToken = foundationToken
        red = foundationToken.red
        green = foundationToken.green
        blue = foundationToken.blue
        opacity = foundationToken.opacity
    }

    var color: Color { foundationToken.color }
    var uiColor: UIColor { foundationToken.uiColor }
    var relativeLuminance: Double { foundationToken.relativeLuminance }

    func contrastRatio(with other: VisualColorToken) -> Double {
        foundationToken.contrastRatio(with: other.foundationToken)
    }

    var hexRGB: String { foundationToken.hexRGB }
}

struct AdaptiveVisualColorToken: Equatable {
    let foundationToken: HibiLensAdaptiveColorToken
    let day: VisualColorToken
    let dark: VisualColorToken

    init(day: VisualColorToken, dark: VisualColorToken) {
        self.init(
            foundationToken: HibiLensAdaptiveColorToken(
                day: day.foundationToken,
                dark: dark.foundationToken
            )
        )
    }

    init(foundationToken: HibiLensAdaptiveColorToken) {
        self.foundationToken = foundationToken
        day = VisualColorToken(foundationToken: foundationToken.day)
        dark = VisualColorToken(foundationToken: foundationToken.dark)
    }

    var color: Color { foundationToken.color }
    var uiColor: UIColor { foundationToken.uiColor }

    func value(for interfaceStyle: UIUserInterfaceStyle) -> VisualColorToken {
        VisualColorToken(foundationToken: foundationToken.value(for: interfaceStyle))
    }
}

enum AppColorToken {
    static let galleryBackground = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.background
    )
    static let galleryBand = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.sectionSurface
    )
    static let keepsakeCard = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.cardSurface
    )
    static let keepsakeCardRaised = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.raisedCardSurface
    )
    static let subjectStage = keepsakeCard
    static let subjectStageHighlight = keepsakeCard
    static let textPrimary = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.primaryText
    )
    static let textSecondary = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.secondaryText
    )
    static let navigationInactive = textSecondary
    static let textTertiary = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.tertiaryText
    )
    static let textJapanese = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.contentPrimaryText
    )
    static let lensAccent = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.primaryAccent
    )
    static let lensAccentDeep = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.primaryAccentDeep
    )
    static let lensMuted = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.primaryAccentMuted
    )
    static let discoveryAccent = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.secondaryAccent
    )
    static let discoveryMuted = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.secondaryAccentMuted
    )
    static let cameraFocus = VisualColorToken(
        foundationToken: HibiLensPalette.cameraFocus
    )
    static let success = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.success
    )
    static let warning = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.warning
    )
    static let destructiveMuted = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.destructiveMuted
    )
    static let outline = AdaptiveVisualColorToken(
        foundationToken: HibiLensPalette.outline
    )

    // Product-specific Personal badge contrast remains local.
    static let profileBadgeForeground = AdaptiveVisualColorToken(
        day: VisualColorToken(red: 242, green: 249, blue: 251),
        dark: VisualColorToken(red: 23, green: 26, blue: 25)
    )
}

struct AppTheme: HibiLensTheme {
    enum SurfaceDepth {
        case base
        case section
        case card
        case elevated

        var foundationDepth: HibiLensSurfaceDepth {
            switch self {
            case .base:
                .base
            case .section:
                .section
            case .card:
                .card
            case .elevated:
                .elevated
            }
        }
    }

    enum ReviewCardImageStage: Equatable {
        case integratedWithCardSurface

        var fill: Color {
            switch self {
            case .integratedWithCardSurface:
                .clear
            }
        }
    }

    private var foundation: HibiLensBaseTheme { HibiLensBaseTheme() }

    nonisolated init() {}

    var background: Color { foundation.background }
    var primaryText: Color { foundation.primaryText }
    var secondaryText: Color { foundation.secondaryText }
    var tertiaryText: Color { foundation.tertiaryText }
    var contentPrimaryText: Color { foundation.contentPrimaryText }

    var surfaceBase: Color { foundation.surfaceBase }
    var surfaceSecondarySection: Color { foundation.surfaceSecondarySection }
    var surfaceInteractiveCard: Color { foundation.surfaceInteractiveCard }
    var surfaceInteractiveCardEmphasis: Color { foundation.surfaceInteractiveCardEmphasis }
    var surfaceInteractiveHighest: Color { foundation.surfaceInteractiveHighest }
    var surfaceImagePlaceholder: Color { foundation.surfaceImagePlaceholder }
    var surfaceInteractiveControl: Color { foundation.surfaceInteractiveControl }
    var surfaceHighEmphasis: Color { foundation.surfaceHighEmphasis }

    var accentPrimaryStrong: Color { foundation.accentPrimaryStrong }
    var accentPrimaryGradientEnd: Color { foundation.accentPrimaryGradientEnd }
    var accentPrimarySoft: Color { foundation.accentPrimarySoft }
    var accentSupportStrong: Color { foundation.accentSupportStrong }
    var accentSupportMuted: Color { foundation.accentSupportMuted }
    var success: Color { foundation.success }
    var warning: Color { foundation.warning }
    var destructiveMuted: Color { foundation.destructiveMuted }
    var outlineVariant: Color { foundation.outlineVariant }

    var glassShellTint: Color { foundation.glassShellTint }
    var activeNavigationGlassTint: Color { foundation.activeNavigationGlassTint }
    var inactiveNavigationGlassTint: Color { foundation.inactiveNavigationGlassTint }
    var activeNavGlassTint: Color { activeNavigationGlassTint }
    var inactiveNavGlassTint: Color { inactiveNavigationGlassTint }

    var cameraPreviewBase: Color { foundation.cameraPreviewBase }
    var cameraPreviewScrim: Color { foundation.cameraPreviewScrim }
    var cameraControlSurface: Color { foundation.cameraControlSurface }
    var cameraControlForeground: Color { foundation.cameraControlForeground }
    var cameraGuidanceStroke: Color { foundation.cameraGuidanceStroke }
    var cameraGuidanceAccent: Color { foundation.cameraGuidanceAccent }
    var cameraShutterOuterSurface: Color { foundation.cameraShutterOuterSurface }
    var cameraShutterInnerSurface: Color { foundation.cameraShutterInnerSurface }
    var cameraShutterCore: Color { foundation.cameraShutterCore }
    var cameraMessageSurface: Color { foundation.cameraMessageSurface }
    var cameraMessagePrimaryText: Color { foundation.cameraMessagePrimaryText }
    var cameraMessageSecondaryText: Color { foundation.cameraMessageSecondaryText }

    var buttonPrimaryGradientStart: Color { foundation.buttonPrimaryGradientStart }
    var buttonPrimaryGradientEnd: Color { foundation.buttonPrimaryGradientEnd }
    var buttonPrimaryForeground: Color { foundation.buttonPrimaryForeground }
    var buttonSecondaryFill: Color { foundation.buttonSecondaryFill }
    var buttonSecondaryForeground: Color { foundation.buttonSecondaryForeground }
    var buttonTertiaryForeground: Color { foundation.buttonTertiaryForeground }
    var inputFill: Color { foundation.inputFill }
    var inputFocusedFill: Color { foundation.inputFocusedFill }
    var inputForeground: Color { foundation.inputForeground }
    var inputPlaceholder: Color { foundation.inputPlaceholder }
    var inputHelperText: Color { foundation.inputHelperText }

    var usesExplicitDividersByDefault: Bool { foundation.usesExplicitDividersByDefault }
    var prefersTonalLayeringOverShadows: Bool { foundation.prefersTonalLayeringOverShadows }
    var allowsStandardIOSShadows: Bool { foundation.allowsStandardIOSShadows }
    var ambientShadowTint: Color { foundation.ambientShadowTint }
    var ambientShadowRadius: CGFloat { foundation.ambientShadowRadius }
    var ambientShadowYOffset: CGFloat { foundation.ambientShadowYOffset }

    func surfaceColor(for depth: HibiLensSurfaceDepth) -> Color {
        foundation.surfaceColor(for: depth)
    }

    func shouldUseAmbientShadow(for depth: HibiLensSurfaceDepth) -> Bool {
        foundation.shouldUseAmbientShadow(for: depth)
    }

    func surfaceColor(for depth: SurfaceDepth) -> Color {
        foundation.surfaceColor(for: depth.foundationDepth)
    }

    func shouldUseAmbientShadow(for depth: SurfaceDepth) -> Bool {
        foundation.shouldUseAmbientShadow(for: depth.foundationDepth)
    }

    // Hibi Lens compatibility aliases
    var accentPrimaryMuted: Color { accentPrimaryGradientEnd }
    var galleryBackground: Color { foundation.background }
    var galleryBand: Color { foundation.surfaceSecondarySection }
    var keepsakeCard: Color { HibiLensPalette.cardSurface.color }
    var keepsakeCardRaised: Color { HibiLensPalette.raisedCardSurface.color }
    var subjectStage: Color { keepsakeCard }
    var subjectStageHighlight: Color { keepsakeCard }
    var textJapanese: Color { foundation.contentPrimaryText }
    var lensAccent: Color { foundation.accentPrimaryStrong }
    var lensMuted: Color { foundation.accentPrimarySoft }
    var discoveryAccent: Color { AppColorToken.discoveryAccent.color }
    var discoveryMuted: Color { foundation.accentSupportMuted }
    var navigationInactiveText: Color { foundation.secondaryText }
    var cardSecondaryText: Color { foundation.tertiaryText }
    var reviewCardImageStage: ReviewCardImageStage { .integratedWithCardSurface }
    var cameraFocus: Color { HibiLensPalette.cameraFocus.color }

    var onSurface: Color { primaryText }
    var onSurfaceVariant: Color { cardSecondaryText }
    var tertiary: Color { secondaryText }

    // Personal/profile roles remain product-local.
    var profileHighlightSurfaceStart: Color { surfaceInteractiveHighest }
    var profileHighlightSurfaceEnd: Color { surfaceInteractiveHighest.opacity(0.96) }
    var profileDecorationPrimary: Color { tertiary.opacity(0.05) }
    var profileDecorationSecondary: Color { onSurfaceVariant.opacity(0.05) }
    var profileBadgeForeground: Color {
        AppColorToken.profileBadgeForeground.color
    }
    var profileBadgeBackground: Color { tertiary }
    var profileSupportSurface: Color { surfaceInteractiveHighest }

    var ghostBorder: Color {
        outlineVariant.opacity(0.15)
    }
}
