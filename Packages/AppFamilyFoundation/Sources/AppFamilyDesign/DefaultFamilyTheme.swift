import SwiftUI

@MainActor
public struct DefaultFamilyTheme: FamilyTheme {
    public init() {}

    public var background: Color { DefaultFamilyPalette.background.color }
    public var primaryText: Color { DefaultFamilyPalette.primaryText.color }
    public var secondaryText: Color { DefaultFamilyPalette.secondaryText.color }
    public var tertiaryText: Color { DefaultFamilyPalette.tertiaryText.color }
    public var contentPrimaryText: Color { DefaultFamilyPalette.contentPrimaryText.color }

    public var surfaceBase: Color { DefaultFamilyPalette.background.color }
    public var surfaceSecondarySection: Color { DefaultFamilyPalette.sectionSurface.color }
    public var surfaceInteractiveCard: Color { DefaultFamilyPalette.cardSurface.color }
    public var surfaceInteractiveCardEmphasis: Color { DefaultFamilyPalette.cardSurface.color }
    public var surfaceInteractiveHighest: Color { DefaultFamilyPalette.cardSurface.color }
    public var surfaceImagePlaceholder: Color { DefaultFamilyPalette.cardSurface.color }
    public var surfaceInteractiveControl: Color {
        DefaultFamilyPalette.primaryAccentMuted.color.opacity(0.72)
    }
    public var surfaceHighEmphasis: Color { surfaceInteractiveControl }

    public var accentPrimaryStrong: Color { DefaultFamilyPalette.primaryAccent.color }
    public var accentPrimaryGradientEnd: Color {
        DefaultFamilyPalette.primaryAccentDeep.color
    }
    public var accentPrimarySoft: Color { DefaultFamilyPalette.primaryAccentMuted.color }
    public var accentSupportStrong: Color { DefaultFamilyPalette.primaryAccentMuted.color }
    public var accentSupportMuted: Color { DefaultFamilyPalette.secondaryAccentMuted.color }
    public var success: Color { DefaultFamilyPalette.success.color }
    public var warning: Color { DefaultFamilyPalette.warning.color }
    public var destructiveMuted: Color { DefaultFamilyPalette.destructiveMuted.color }
    public var outlineVariant: Color { DefaultFamilyPalette.outline.color }

    public var glassShellTint: Color { Color.white.opacity(0.2) }
    public var activeNavigationGlassTint: Color {
        DefaultFamilyPalette.primaryAccentMuted.color.opacity(0.34)
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

    public func surfaceColor(for depth: FamilySurfaceDepth) -> Color {
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

    public func shouldUseAmbientShadow(for depth: FamilySurfaceDepth) -> Bool {
        depth == .elevated
    }
}
