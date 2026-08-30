import AppFamilyDesign
import SwiftUI
import UIKit
import XCTest
@testable import JapCapture

final class VisualDesignTokenTests: XCTestCase {
    func testAppPaletteAliasesDefaultFamilyPalette() {
        XCTAssertEqual(AppColorToken.galleryBackground.familyToken, DefaultFamilyPalette.background)
        XCTAssertEqual(AppColorToken.galleryBand.familyToken, DefaultFamilyPalette.sectionSurface)
        XCTAssertEqual(AppColorToken.keepsakeCard.familyToken, DefaultFamilyPalette.cardSurface)
        XCTAssertEqual(AppColorToken.keepsakeCardRaised.familyToken, DefaultFamilyPalette.raisedCardSurface)
        XCTAssertEqual(AppColorToken.textJapanese.familyToken, DefaultFamilyPalette.contentPrimaryText)
        XCTAssertEqual(AppColorToken.lensAccent.familyToken, DefaultFamilyPalette.primaryAccent)
        XCTAssertEqual(AppColorToken.discoveryAccent.familyToken, DefaultFamilyPalette.secondaryAccent)
    }

    func testAppThemeConformsToFamilyTheme() {
        func acceptsFamilyTheme<T: FamilyTheme>(_: T) {}
        acceptsFamilyTheme(AppTheme())
    }

    func testAppThemeForwardsEveryFamilyColorRole() {
        let appTheme = AppTheme()
        let familyTheme = DefaultFamilyTheme()
        let mappings: [(String, Color, Color)] = [
            ("background", appTheme.background, familyTheme.background),
            ("primaryText", appTheme.primaryText, familyTheme.primaryText),
            ("secondaryText", appTheme.secondaryText, familyTheme.secondaryText),
            ("tertiaryText", appTheme.tertiaryText, familyTheme.tertiaryText),
            ("contentPrimaryText", appTheme.contentPrimaryText, familyTheme.contentPrimaryText),
            ("surfaceBase", appTheme.surfaceBase, familyTheme.surfaceBase),
            (
                "surfaceSecondarySection",
                appTheme.surfaceSecondarySection,
                familyTheme.surfaceSecondarySection
            ),
            (
                "surfaceInteractiveCard",
                appTheme.surfaceInteractiveCard,
                familyTheme.surfaceInteractiveCard
            ),
            (
                "surfaceInteractiveCardEmphasis",
                appTheme.surfaceInteractiveCardEmphasis,
                familyTheme.surfaceInteractiveCardEmphasis
            ),
            (
                "surfaceInteractiveHighest",
                appTheme.surfaceInteractiveHighest,
                familyTheme.surfaceInteractiveHighest
            ),
            (
                "surfaceImagePlaceholder",
                appTheme.surfaceImagePlaceholder,
                familyTheme.surfaceImagePlaceholder
            ),
            (
                "surfaceInteractiveControl",
                appTheme.surfaceInteractiveControl,
                familyTheme.surfaceInteractiveControl
            ),
            (
                "surfaceHighEmphasis",
                appTheme.surfaceHighEmphasis,
                familyTheme.surfaceHighEmphasis
            ),
            (
                "accentPrimaryStrong",
                appTheme.accentPrimaryStrong,
                familyTheme.accentPrimaryStrong
            ),
            (
                "accentPrimaryGradientEnd",
                appTheme.accentPrimaryGradientEnd,
                familyTheme.accentPrimaryGradientEnd
            ),
            (
                "accentPrimarySoft",
                appTheme.accentPrimarySoft,
                familyTheme.accentPrimarySoft
            ),
            (
                "accentSupportStrong",
                appTheme.accentSupportStrong,
                familyTheme.accentSupportStrong
            ),
            (
                "accentSupportMuted",
                appTheme.accentSupportMuted,
                familyTheme.accentSupportMuted
            ),
            ("success", appTheme.success, familyTheme.success),
            ("warning", appTheme.warning, familyTheme.warning),
            ("destructiveMuted", appTheme.destructiveMuted, familyTheme.destructiveMuted),
            ("outlineVariant", appTheme.outlineVariant, familyTheme.outlineVariant),
            ("glassShellTint", appTheme.glassShellTint, familyTheme.glassShellTint),
            (
                "activeNavigationGlassTint",
                appTheme.activeNavigationGlassTint,
                familyTheme.activeNavigationGlassTint
            ),
            (
                "inactiveNavigationGlassTint",
                appTheme.inactiveNavigationGlassTint,
                familyTheme.inactiveNavigationGlassTint
            ),
            ("cameraPreviewBase", appTheme.cameraPreviewBase, familyTheme.cameraPreviewBase),
            ("cameraPreviewScrim", appTheme.cameraPreviewScrim, familyTheme.cameraPreviewScrim),
            (
                "cameraControlSurface",
                appTheme.cameraControlSurface,
                familyTheme.cameraControlSurface
            ),
            (
                "cameraControlForeground",
                appTheme.cameraControlForeground,
                familyTheme.cameraControlForeground
            ),
            (
                "cameraGuidanceStroke",
                appTheme.cameraGuidanceStroke,
                familyTheme.cameraGuidanceStroke
            ),
            (
                "cameraGuidanceAccent",
                appTheme.cameraGuidanceAccent,
                familyTheme.cameraGuidanceAccent
            ),
            (
                "cameraShutterOuterSurface",
                appTheme.cameraShutterOuterSurface,
                familyTheme.cameraShutterOuterSurface
            ),
            (
                "cameraShutterInnerSurface",
                appTheme.cameraShutterInnerSurface,
                familyTheme.cameraShutterInnerSurface
            ),
            ("cameraShutterCore", appTheme.cameraShutterCore, familyTheme.cameraShutterCore),
            (
                "cameraMessageSurface",
                appTheme.cameraMessageSurface,
                familyTheme.cameraMessageSurface
            ),
            (
                "cameraMessagePrimaryText",
                appTheme.cameraMessagePrimaryText,
                familyTheme.cameraMessagePrimaryText
            ),
            (
                "cameraMessageSecondaryText",
                appTheme.cameraMessageSecondaryText,
                familyTheme.cameraMessageSecondaryText
            ),
            (
                "buttonPrimaryGradientStart",
                appTheme.buttonPrimaryGradientStart,
                familyTheme.buttonPrimaryGradientStart
            ),
            (
                "buttonPrimaryGradientEnd",
                appTheme.buttonPrimaryGradientEnd,
                familyTheme.buttonPrimaryGradientEnd
            ),
            (
                "buttonPrimaryForeground",
                appTheme.buttonPrimaryForeground,
                familyTheme.buttonPrimaryForeground
            ),
            (
                "buttonSecondaryFill",
                appTheme.buttonSecondaryFill,
                familyTheme.buttonSecondaryFill
            ),
            (
                "buttonSecondaryForeground",
                appTheme.buttonSecondaryForeground,
                familyTheme.buttonSecondaryForeground
            ),
            (
                "buttonTertiaryForeground",
                appTheme.buttonTertiaryForeground,
                familyTheme.buttonTertiaryForeground
            ),
            ("inputFill", appTheme.inputFill, familyTheme.inputFill),
            ("inputFocusedFill", appTheme.inputFocusedFill, familyTheme.inputFocusedFill),
            ("inputForeground", appTheme.inputForeground, familyTheme.inputForeground),
            ("inputPlaceholder", appTheme.inputPlaceholder, familyTheme.inputPlaceholder),
            ("inputHelperText", appTheme.inputHelperText, familyTheme.inputHelperText),
            ("ambientShadowTint", appTheme.ambientShadowTint, familyTheme.ambientShadowTint)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
            for (name, appColor, familyColor) in mappings {
                XCTAssertEqual(
                    UIColor(appColor).resolvedColor(with: traits),
                    UIColor(familyColor).resolvedColor(with: traits),
                    "\(name) \(interfaceStyle)"
                )
            }
        }
    }

    func testAppThemeForwardsEveryFamilyPolicyAndDepthMethod() {
        let appTheme = AppTheme()
        let familyTheme = DefaultFamilyTheme()

        XCTAssertEqual(
            appTheme.usesExplicitDividersByDefault,
            familyTheme.usesExplicitDividersByDefault
        )
        XCTAssertEqual(
            appTheme.prefersTonalLayeringOverShadows,
            familyTheme.prefersTonalLayeringOverShadows
        )
        XCTAssertEqual(
            appTheme.allowsStandardIOSShadows,
            familyTheme.allowsStandardIOSShadows
        )
        XCTAssertEqual(appTheme.ambientShadowRadius, familyTheme.ambientShadowRadius)
        XCTAssertEqual(appTheme.ambientShadowYOffset, familyTheme.ambientShadowYOffset)

        for depth in FamilySurfaceDepth.allCases {
            for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
                XCTAssertEqual(
                    UIColor(appTheme.surfaceColor(for: depth)).resolvedColor(with: traits),
                    UIColor(familyTheme.surfaceColor(for: depth)).resolvedColor(with: traits),
                    "\(depth) \(interfaceStyle)"
                )
            }
            XCTAssertEqual(
                appTheme.shouldUseAmbientShadow(for: depth),
                familyTheme.shouldUseAmbientShadow(for: depth),
                "\(depth)"
            )
        }
    }

    func testAppTypographyCompatibilityUsesFamilyPolicy() {
        XCTAssertEqual(
            AppTypography.japaneseLineHeightDefaultMultiplier,
            FamilyTypography.contentLineHeightDefaultMultiplier
        )
        XCTAssertEqual(
            AppTypography.lineSpacing(for: 20),
            FamilyTypography.contentLineSpacing(for: 20)
        )
    }

    func testAppSurfaceDepthCompatibilityMapsToFamilyPolicy() {
        let appTheme = AppTheme()
        let familyTheme = DefaultFamilyTheme()
        let mappings: [(AppTheme.SurfaceDepth, FamilySurfaceDepth)] = [
            (.base, .base),
            (.section, .section),
            (.card, .card),
            (.elevated, .elevated)
        ]

        for (appDepth, familyDepth) in mappings {
            XCTAssertEqual(appDepth.familyDepth, familyDepth)
            for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
                XCTAssertEqual(
                    UIColor(appTheme.surfaceColor(for: appDepth)).resolvedColor(with: traits),
                    UIColor(familyTheme.surfaceColor(for: familyDepth)).resolvedColor(with: traits)
                )
            }
            XCTAssertEqual(
                appTheme.shouldUseAmbientShadow(for: appDepth),
                familyTheme.shouldUseAmbientShadow(for: familyDepth)
            )
        }
    }

    func testAppThemePreservesProductAccentAliases() {
        let theme = AppTheme()
        let mappings: [(String, Color, FamilyAdaptiveColorToken)] = [
            ("accentPrimaryMuted", theme.accentPrimaryMuted, DefaultFamilyPalette.primaryAccentDeep),
            ("lensMuted", theme.lensMuted, DefaultFamilyPalette.primaryAccentMuted),
            ("discoveryAccent", theme.discoveryAccent, DefaultFamilyPalette.secondaryAccent),
            ("discoveryMuted", theme.discoveryMuted, DefaultFamilyPalette.secondaryAccentMuted)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
            for (name, appColor, familyToken) in mappings {
                XCTAssertEqual(
                    UIColor(appColor).resolvedColor(with: traits),
                    familyToken.uiColor.resolvedColor(with: traits),
                    "\(name) \(interfaceStyle)"
                )
            }
        }
    }

    func testAdaptiveGalleryPaletteMatchesApprovedDayAndDarkValues() {
        let expected: [(String, AdaptiveVisualColorToken, String, String)] = [
            ("galleryBackground", AppColorToken.galleryBackground, "#F8F6F0", "#171A19"),
            ("galleryBand", AppColorToken.galleryBand, "#ECEAE2", "#272C2A"),
            ("keepsakeCard", AppColorToken.keepsakeCard, "#FFFDF8", "#222624"),
            ("keepsakeCardRaised", AppColorToken.keepsakeCardRaised, "#FFFFFF", "#2B302E"),
            ("textPrimary", AppColorToken.textPrimary, "#26302D", "#F1F0EA"),
            ("textSecondary", AppColorToken.textSecondary, "#66706B", "#B0B8B3"),
            ("textTertiary", AppColorToken.textTertiary, "#8A918C", "#89938E"),
            ("textJapanese", AppColorToken.textJapanese, "#1F2926", "#F4F3EE"),
            ("lensAccent", AppColorToken.lensAccent, "#2F5D50", "#8FB3A6"),
            ("lensAccentDeep", AppColorToken.lensAccentDeep, "#264C42", "#628D7E"),
            ("lensMuted", AppColorToken.lensMuted, "#D9E5DF", "#34443F"),
            ("discoveryAccent", AppColorToken.discoveryAccent, "#D6A84F", "#D7B363"),
            ("discoveryMuted", AppColorToken.discoveryMuted, "#F3E4C0", "#4A402A"),
            ("success", AppColorToken.success, "#4F7D65", "#86A991"),
            ("warning", AppColorToken.warning, "#C6923E", "#D2A24F"),
            ("destructiveMuted", AppColorToken.destructiveMuted, "#B85A54", "#D77B73"),
            ("outline", AppColorToken.outline, "#ADB3B0", "#65706B"),
            ("profileBadgeForeground", AppColorToken.profileBadgeForeground, "#F2F9FB", "#171A19")
        ]

        for (name, token, day, dark) in expected {
            XCTAssertEqual(token.day.hexRGB, day, "\(name) Day")
            XCTAssertEqual(token.dark.hexRGB, dark, "\(name) Dark")
        }
    }

    func testAdaptiveTokensResolveByInterfaceStyle() {
        let token = AppColorToken.galleryBackground
        XCTAssertEqual(token.value(for: .light), token.day)
        XCTAssertEqual(token.value(for: .dark), token.dark)
        XCTAssertEqual(token.value(for: .unspecified), token.day)
    }

    func testLiftedSubjectStageUsesContinuousKeepsakeCardSurface() {
        XCTAssertEqual(AppColorToken.subjectStage, AppColorToken.keepsakeCard)
        XCTAssertEqual(AppColorToken.subjectStageHighlight, AppColorToken.keepsakeCard)
    }

    func testNavigationInactiveUsesSecondaryTextToken() {
        XCTAssertEqual(AppColorToken.navigationInactive, AppColorToken.textSecondary)
    }

    func testKeyDayAndDarkTextPairsMeetMinimumContrast() {
        assertContrast(AppColorToken.textPrimary, against: AppColorToken.galleryBackground, name: "primary/background")
        assertContrast(AppColorToken.textSecondary, against: AppColorToken.galleryBackground, name: "secondary/background")
        assertContrast(AppColorToken.textJapanese, against: AppColorToken.keepsakeCard, name: "Japanese/card")
        assertContrast(AppColorToken.lensAccent, against: AppColorToken.keepsakeCard, name: "lens/card")
        assertContrast(AppColorToken.lensAccentDeep, against: AppColorToken.galleryBackground, name: "primary button/background")
        assertContrast(AppColorToken.navigationInactive, against: AppColorToken.galleryBackground, name: "inactive navigation/background")
    }

    private func assertContrast(
        _ foreground: AdaptiveVisualColorToken,
        against background: AdaptiveVisualColorToken,
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(foreground.day.contrastRatio(with: background.day), 4.5, "\(name) Day", file: file, line: line)
        XCTAssertGreaterThanOrEqual(foreground.dark.contrastRatio(with: background.dark), 4.5, "\(name) Dark", file: file, line: line)
    }

    func testTypographyUsesModernSansWithoutNegativeTracking() {
        XCTAssertEqual(AppTypography.displayTracking, 0)
        XCTAssertEqual(AppTypography.displayHeroTracking, 0)
        XCTAssertEqual(AppTypography.displayMetricTracking, 0)
        XCTAssertEqual(AppTypography.headlineTracking, 0)
        XCTAssertGreaterThanOrEqual(AppTypography.labelTracking, 0)
        XCTAssertGreaterThanOrEqual(AppTypography.sectionLabelTracking, 0)
    }

    func testVisualLayoutTokensMatchApprovedComponentScale() {
        XCTAssertEqual(AppLayout.galleryCardGap, 16)
        XCTAssertEqual(AppLayout.keepsakeCardCornerRadius, 22)
        XCTAssertEqual(AppLayout.compactKeepsakeCardCornerRadius, 14)
        XCTAssertEqual(AppLayout.subjectStageCornerRadius, 18)
        XCTAssertEqual(AppLayout.dailyDiscoveryMinHeight, 180)
        XCTAssertEqual(AppLayout.dailyDiscoveryMaxHeight, 240)
        XCTAssertEqual(AppLayout.detailSubjectStageMinHeight, 320)
        XCTAssertEqual(AppLayout.detailSubjectStageMaxHeight, 420)
    }

    func testMotionTokensMatchFocusLiftSettleDirection() {
        XCTAssertEqual(AppMotion.focusLock.duration, 0.22, accuracy: 0.001)
        XCTAssertEqual(AppMotion.focusPulse.duration, 0.9, accuracy: 0.001)
        XCTAssertEqual(AppMotion.subjectLift.duration, 0.58, accuracy: 0.001)
        XCTAssertEqual(AppMotion.cardSettle.duration, 0.42, accuracy: 0.001)
        XCTAssertEqual(AppMotion.detailExpand.duration, 0.42, accuracy: 0.001)
        XCTAssertEqual(AppMotion.detailDismiss.duration, 0.32, accuracy: 0.001)
        XCTAssertEqual(AppMotion.discoveryHighlight.duration, 1.1, accuracy: 0.001)
        XCTAssertEqual(AppMotion.reviewInteraction.duration, 0.16, accuracy: 0.001)
        XCTAssertEqual(AppMotion.rootNavigation.duration, 0.30, accuracy: 0.001)
    }
}
