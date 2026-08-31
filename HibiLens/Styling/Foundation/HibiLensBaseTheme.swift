import SwiftUI

@MainActor
public struct HibiLensBaseTheme: HibiLensTheme {
    public init() {}

    public var background: Color { HibiLensPalette.background.color }
    public var primaryText: Color { HibiLensPalette.primaryText.color }
    public var secondaryText: Color { HibiLensPalette.secondaryText.color }
    public var tertiaryText: Color { HibiLensPalette.tertiaryText.color }
    public var contentPrimaryText: Color { HibiLensPalette.contentPrimaryText.color }

    public var surfaceBase: Color { HibiLensPalette.background.color }
    public var surfaceSecondarySection: Color { HibiLensPalette.sectionSurface.color }
    public var surfaceInteractiveCard: Color { HibiLensPalette.cardSurface.color }
    public var surfaceInteractiveCardEmphasis: Color { HibiLensPalette.cardSurface.color }
    public var surfaceInteractiveHighest: Color { HibiLensPalette.cardSurface.color }
    public var surfaceImagePlaceholder: Color { HibiLensPalette.cardSurface.color }
    public var surfaceInteractiveControl: Color {
        HibiLensPalette.primaryAccentMuted.color.opacity(0.72)
    }
    public var surfaceHighEmphasis: Color { surfaceInteractiveControl }

    public var accentPrimaryStrong: Color { HibiLensPalette.primaryAccent.color }
    public var accentPrimaryGradientEnd: Color {
        HibiLensPalette.primaryAccentDeep.color
    }
    public var accentPrimarySoft: Color { HibiLensPalette.primaryAccentMuted.color }
    public var accentSupportStrong: Color { HibiLensPalette.primaryAccentMuted.color }
    public var accentSupportMuted: Color { HibiLensPalette.secondaryAccentMuted.color }
    public var success: Color { HibiLensPalette.success.color }
    public var warning: Color { HibiLensPalette.warning.color }
    public var destructiveMuted: Color { HibiLensPalette.destructiveMuted.color }
    public var outlineVariant: Color { HibiLensPalette.outline.color }

    public var glassShellTint: Color { Color.white.opacity(0.2) }
    public var activeNavigationGlassTint: Color {
        HibiLensPalette.primaryAccentMuted.color.opacity(0.34)
    }
    public var inactiveNavigationGlassTint: Color { Color.white.opacity(0.1) }

    public var cameraPreviewBase: Color { .black }
    public var cameraPreviewScrim: Color { .black.opacity(0.05) }
    public var cameraControlSurface: Color { .black.opacity(0.18) }
    public var cameraControlForeground: Color { .white.opacity(0.92) }
    public var cameraGuidanceStroke: Color { .white.opacity(0.6) }
    public var cameraGuidanceAccent: Color { .white.opacity(0.4) }
    public var cameraShutterOuterSurface: Color { .white.opacity(0.18) }
    public var cameraShutterInnerSurface: Color { .white }
    public var cameraShutterCore: Color {
        Color(
            red: 95.0 / 255.0,
            green: 103.0 / 255.0,
            blue: 105.0 / 255.0
        )
    }
    public var cameraMessageSurface: Color { .black.opacity(0.42) }
    public var cameraMessagePrimaryText: Color { .white }
    public var cameraMessageSecondaryText: Color { .white.opacity(0.82) }

    public var buttonPrimaryGradientStart: Color { accentPrimaryStrong }
    public var buttonPrimaryGradientEnd: Color { accentPrimaryGradientEnd }
    public var buttonPrimaryForeground: Color { surfaceBase }
    public var buttonSecondaryFill: Color { surfaceHighEmphasis }
    public var buttonSecondaryForeground: Color { primaryText }
    public var buttonTertiaryForeground: Color { accentPrimaryStrong }
    public var inputFill: Color { surfaceSecondarySection }
    public var inputFocusedFill: Color { surfaceHighEmphasis }
    public var inputForeground: Color { primaryText }
    public var inputPlaceholder: Color { secondaryText.opacity(0.82) }
    public var inputHelperText: Color { tertiaryText }

    public var usesExplicitDividersByDefault: Bool { false }
    public var prefersTonalLayeringOverShadows: Bool { true }
    public var allowsStandardIOSShadows: Bool { false }
    public var ambientShadowTint: Color { accentPrimaryStrong.opacity(0.08) }
    public var ambientShadowRadius: CGFloat { 24 }
    public var ambientShadowYOffset: CGFloat { 8 }

    public func surfaceColor(for depth: HibiLensSurfaceDepth) -> Color {
        switch depth {
        case .base:
            surfaceBase
        case .section:
            surfaceSecondarySection
        case .card:
            surfaceInteractiveCard
        case .elevated:
            surfaceInteractiveHighest
        }
    }

    public func shouldUseAmbientShadow(for depth: HibiLensSurfaceDepth) -> Bool {
        depth == .elevated
    }
}
