//
//  AppTheme.swift
//  JapCapture
//
//  Created by kiethrios on 2026/4/10.
//

import AppFamilyDesign
import SwiftUI
import UIKit

struct VisualColorToken: Equatable {
    let familyToken: FamilyVisualColorToken

    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        let familyToken = FamilyVisualColorToken(
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
        self.init(familyToken: familyToken)
    }

    init(familyToken: FamilyVisualColorToken) {
        self.familyToken = familyToken
        red = familyToken.red
        green = familyToken.green
        blue = familyToken.blue
        opacity = familyToken.opacity
    }

    var color: Color { familyToken.color }
    var uiColor: UIColor { familyToken.uiColor }
    var relativeLuminance: Double { familyToken.relativeLuminance }

    func contrastRatio(with other: VisualColorToken) -> Double {
        familyToken.contrastRatio(with: other.familyToken)
    }

    var hexRGB: String { familyToken.hexRGB }
}

struct AdaptiveVisualColorToken: Equatable {
    let familyToken: FamilyAdaptiveColorToken
    let day: VisualColorToken
    let dark: VisualColorToken

    init(day: VisualColorToken, dark: VisualColorToken) {
        self.init(
            familyToken: FamilyAdaptiveColorToken(
                day: day.familyToken,
                dark: dark.familyToken
            )
        )
    }

    init(familyToken: FamilyAdaptiveColorToken) {
        self.familyToken = familyToken
        day = VisualColorToken(familyToken: familyToken.day)
        dark = VisualColorToken(familyToken: familyToken.dark)
    }

    var color: Color { familyToken.color }
    var uiColor: UIColor { familyToken.uiColor }

    func value(for interfaceStyle: UIUserInterfaceStyle) -> VisualColorToken {
        VisualColorToken(familyToken: familyToken.value(for: interfaceStyle))
    }
}

enum AppColorToken {
    static let galleryBackground = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.background
    )
    static let galleryBand = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.sectionSurface
    )
    static let keepsakeCard = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.cardSurface
    )
    static let keepsakeCardRaised = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.raisedCardSurface
    )
    static let subjectStage = keepsakeCard
    static let subjectStageHighlight = keepsakeCard
    static let textPrimary = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.primaryText
    )
    static let textSecondary = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.secondaryText
    )
    static let navigationInactive = textSecondary
    static let textTertiary = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.tertiaryText
    )
    static let textJapanese = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.contentPrimaryText
    )
    static let lensAccent = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.primaryAccent
    )
    static let lensAccentDeep = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.primaryAccentDeep
    )
    static let lensMuted = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.primaryAccentMuted
    )
    static let discoveryAccent = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.secondaryAccent
    )
    static let discoveryMuted = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.secondaryAccentMuted
    )
    static let cameraFocus = VisualColorToken(
        familyToken: DefaultFamilyPalette.cameraFocus
    )
    static let success = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.success
    )
    static let warning = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.warning
    )
    static let destructiveMuted = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.destructiveMuted
    )
    static let outline = AdaptiveVisualColorToken(
        familyToken: DefaultFamilyPalette.outline
    )

    // Product-specific Personal badge contrast remains local.
    static let profileBadgeForeground = AdaptiveVisualColorToken(
        day: VisualColorToken(red: 242, green: 249, blue: 251),
        dark: VisualColorToken(red: 23, green: 26, blue: 25)
    )
}

struct AppTheme: FamilyTheme {
    enum SurfaceDepth {
        case base
        case section
        case card
        case elevated

        var familyDepth: FamilySurfaceDepth {
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

    private var family: DefaultFamilyTheme { DefaultFamilyTheme() }

    nonisolated init() {}

    var background: Color { family.background }
    var primaryText: Color { family.primaryText }
    var secondaryText: Color { family.secondaryText }
    var tertiaryText: Color { family.tertiaryText }
    var contentPrimaryText: Color { family.contentPrimaryText }

    var surfaceBase: Color { family.surfaceBase }
    var surfaceSecondarySection: Color { family.surfaceSecondarySection }
    var surfaceInteractiveCard: Color { family.surfaceInteractiveCard }
    var surfaceInteractiveCardEmphasis: Color { family.surfaceInteractiveCardEmphasis }
    var surfaceInteractiveHighest: Color { family.surfaceInteractiveHighest }
    var surfaceImagePlaceholder: Color { family.surfaceImagePlaceholder }
    var surfaceInteractiveControl: Color { family.surfaceInteractiveControl }
    var surfaceHighEmphasis: Color { family.surfaceHighEmphasis }

    var accentPrimaryStrong: Color { family.accentPrimaryStrong }
    var accentPrimaryGradientEnd: Color { family.accentPrimaryGradientEnd }
    var accentPrimarySoft: Color { family.accentPrimarySoft }
    var accentSupportStrong: Color { family.accentSupportStrong }
    var accentSupportMuted: Color { family.accentSupportMuted }
    var success: Color { family.success }
    var warning: Color { family.warning }
    var destructiveMuted: Color { family.destructiveMuted }
    var outlineVariant: Color { family.outlineVariant }

    var glassShellTint: Color { family.glassShellTint }
    var activeNavigationGlassTint: Color { family.activeNavigationGlassTint }
    var inactiveNavigationGlassTint: Color { family.inactiveNavigationGlassTint }
    var activeNavGlassTint: Color { activeNavigationGlassTint }
    var inactiveNavGlassTint: Color { inactiveNavigationGlassTint }

    var cameraPreviewBase: Color { family.cameraPreviewBase }
    var cameraPreviewScrim: Color { family.cameraPreviewScrim }
    var cameraControlSurface: Color { family.cameraControlSurface }
    var cameraControlForeground: Color { family.cameraControlForeground }
    var cameraGuidanceStroke: Color { family.cameraGuidanceStroke }
    var cameraGuidanceAccent: Color { family.cameraGuidanceAccent }
    var cameraShutterOuterSurface: Color { family.cameraShutterOuterSurface }
    var cameraShutterInnerSurface: Color { family.cameraShutterInnerSurface }
    var cameraShutterCore: Color { family.cameraShutterCore }
    var cameraMessageSurface: Color { family.cameraMessageSurface }
    var cameraMessagePrimaryText: Color { family.cameraMessagePrimaryText }
    var cameraMessageSecondaryText: Color { family.cameraMessageSecondaryText }

    var buttonPrimaryGradientStart: Color { family.buttonPrimaryGradientStart }
    var buttonPrimaryGradientEnd: Color { family.buttonPrimaryGradientEnd }
    var buttonPrimaryForeground: Color { family.buttonPrimaryForeground }
    var buttonSecondaryFill: Color { family.buttonSecondaryFill }
    var buttonSecondaryForeground: Color { family.buttonSecondaryForeground }
    var buttonTertiaryForeground: Color { family.buttonTertiaryForeground }
    var inputFill: Color { family.inputFill }
    var inputFocusedFill: Color { family.inputFocusedFill }
    var inputForeground: Color { family.inputForeground }
    var inputPlaceholder: Color { family.inputPlaceholder }
    var inputHelperText: Color { family.inputHelperText }

    var usesExplicitDividersByDefault: Bool { family.usesExplicitDividersByDefault }
    var prefersTonalLayeringOverShadows: Bool { family.prefersTonalLayeringOverShadows }
    var allowsStandardIOSShadows: Bool { family.allowsStandardIOSShadows }
    var ambientShadowTint: Color { family.ambientShadowTint }
    var ambientShadowRadius: CGFloat { family.ambientShadowRadius }
    var ambientShadowYOffset: CGFloat { family.ambientShadowYOffset }

    func surfaceColor(for depth: FamilySurfaceDepth) -> Color {
        family.surfaceColor(for: depth)
    }

    func shouldUseAmbientShadow(for depth: FamilySurfaceDepth) -> Bool {
        family.shouldUseAmbientShadow(for: depth)
    }

    func surfaceColor(for depth: SurfaceDepth) -> Color {
        family.surfaceColor(for: depth.familyDepth)
    }

    func shouldUseAmbientShadow(for depth: SurfaceDepth) -> Bool {
        family.shouldUseAmbientShadow(for: depth.familyDepth)
    }

    // Hibi Lens compatibility aliases
    var accentPrimaryMuted: Color { accentPrimaryGradientEnd }
    var galleryBackground: Color { family.background }
    var galleryBand: Color { family.surfaceSecondarySection }
    var keepsakeCard: Color { DefaultFamilyPalette.cardSurface.color }
    var keepsakeCardRaised: Color { DefaultFamilyPalette.raisedCardSurface.color }
    var subjectStage: Color { keepsakeCard }
    var subjectStageHighlight: Color { keepsakeCard }
    var textJapanese: Color { family.contentPrimaryText }
    var lensAccent: Color { family.accentPrimaryStrong }
    var lensMuted: Color { family.accentPrimarySoft }
    var discoveryAccent: Color { AppColorToken.discoveryAccent.color }
    var discoveryMuted: Color { family.accentSupportMuted }
    var navigationInactiveText: Color { family.secondaryText }
    var cardSecondaryText: Color { family.tertiaryText }
    var reviewCardImageStage: ReviewCardImageStage { .integratedWithCardSurface }
    var cameraFocus: Color { DefaultFamilyPalette.cameraFocus.color }

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
