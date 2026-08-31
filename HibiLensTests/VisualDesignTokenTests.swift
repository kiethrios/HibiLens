import SwiftUI
import UIKit
import XCTest
@testable import HibiLens

final class VisualDesignTokenTests: XCTestCase {
    func testAppPaletteAliasesHibiLensPalette() {
        XCTAssertEqual(AppColorToken.galleryBackground.foundationToken, HibiLensPalette.background)
        XCTAssertEqual(AppColorToken.galleryBand.foundationToken, HibiLensPalette.sectionSurface)
        XCTAssertEqual(AppColorToken.keepsakeCard.foundationToken, HibiLensPalette.cardSurface)
        XCTAssertEqual(AppColorToken.keepsakeCardRaised.foundationToken, HibiLensPalette.raisedCardSurface)
        XCTAssertEqual(AppColorToken.textJapanese.foundationToken, HibiLensPalette.contentPrimaryText)
        XCTAssertEqual(AppColorToken.lensAccent.foundationToken, HibiLensPalette.primaryAccent)
        XCTAssertEqual(AppColorToken.discoveryAccent.foundationToken, HibiLensPalette.secondaryAccent)
    }

    func testAppThemeConformsToHibiLensTheme() {
        func acceptsHibiLensTheme<T: HibiLensTheme>(_: T) {}
        acceptsHibiLensTheme(AppTheme())
    }

    func testAppThemeForwardsEveryHibiLensColorRole() {
        let appTheme = AppTheme()
        let foundationTheme = HibiLensBaseTheme()
        let mappings: [(String, Color, Color)] = [
            ("background", appTheme.background, foundationTheme.background),
            ("primaryText", appTheme.primaryText, foundationTheme.primaryText),
            ("secondaryText", appTheme.secondaryText, foundationTheme.secondaryText),
            ("tertiaryText", appTheme.tertiaryText, foundationTheme.tertiaryText),
            ("contentPrimaryText", appTheme.contentPrimaryText, foundationTheme.contentPrimaryText),
            ("surfaceBase", appTheme.surfaceBase, foundationTheme.surfaceBase),
            (
                "surfaceSecondarySection",
                appTheme.surfaceSecondarySection,
                foundationTheme.surfaceSecondarySection
            ),
            (
                "surfaceInteractiveCard",
                appTheme.surfaceInteractiveCard,
                foundationTheme.surfaceInteractiveCard
            ),
            (
                "surfaceInteractiveCardEmphasis",
                appTheme.surfaceInteractiveCardEmphasis,
                foundationTheme.surfaceInteractiveCardEmphasis
            ),
            (
                "surfaceInteractiveHighest",
                appTheme.surfaceInteractiveHighest,
                foundationTheme.surfaceInteractiveHighest
            ),
            (
                "surfaceImagePlaceholder",
                appTheme.surfaceImagePlaceholder,
                foundationTheme.surfaceImagePlaceholder
            ),
            (
                "surfaceInteractiveControl",
                appTheme.surfaceInteractiveControl,
                foundationTheme.surfaceInteractiveControl
            ),
            (
                "surfaceHighEmphasis",
                appTheme.surfaceHighEmphasis,
                foundationTheme.surfaceHighEmphasis
            ),
            (
                "accentPrimaryStrong",
                appTheme.accentPrimaryStrong,
                foundationTheme.accentPrimaryStrong
            ),
            (
                "accentPrimaryGradientEnd",
                appTheme.accentPrimaryGradientEnd,
                foundationTheme.accentPrimaryGradientEnd
            ),
            (
                "accentPrimarySoft",
                appTheme.accentPrimarySoft,
                foundationTheme.accentPrimarySoft
            ),
            (
                "accentSupportStrong",
                appTheme.accentSupportStrong,
                foundationTheme.accentSupportStrong
            ),
            (
                "accentSupportMuted",
                appTheme.accentSupportMuted,
                foundationTheme.accentSupportMuted
            ),
            ("success", appTheme.success, foundationTheme.success),
            ("warning", appTheme.warning, foundationTheme.warning),
            ("destructiveMuted", appTheme.destructiveMuted, foundationTheme.destructiveMuted),
            ("outlineVariant", appTheme.outlineVariant, foundationTheme.outlineVariant),
            ("glassShellTint", appTheme.glassShellTint, foundationTheme.glassShellTint),
            (
                "activeNavigationGlassTint",
                appTheme.activeNavigationGlassTint,
                foundationTheme.activeNavigationGlassTint
            ),
            (
                "inactiveNavigationGlassTint",
                appTheme.inactiveNavigationGlassTint,
                foundationTheme.inactiveNavigationGlassTint
            ),
            ("cameraPreviewBase", appTheme.cameraPreviewBase, foundationTheme.cameraPreviewBase),
            ("cameraPreviewScrim", appTheme.cameraPreviewScrim, foundationTheme.cameraPreviewScrim),
            (
                "cameraControlSurface",
                appTheme.cameraControlSurface,
                foundationTheme.cameraControlSurface
            ),
            (
                "cameraControlForeground",
                appTheme.cameraControlForeground,
                foundationTheme.cameraControlForeground
            ),
            (
                "cameraGuidanceStroke",
                appTheme.cameraGuidanceStroke,
                foundationTheme.cameraGuidanceStroke
            ),
            (
                "cameraGuidanceAccent",
                appTheme.cameraGuidanceAccent,
                foundationTheme.cameraGuidanceAccent
            ),
            (
                "cameraShutterOuterSurface",
                appTheme.cameraShutterOuterSurface,
                foundationTheme.cameraShutterOuterSurface
            ),
            (
                "cameraShutterInnerSurface",
                appTheme.cameraShutterInnerSurface,
                foundationTheme.cameraShutterInnerSurface
            ),
            ("cameraShutterCore", appTheme.cameraShutterCore, foundationTheme.cameraShutterCore),
            (
                "cameraMessageSurface",
                appTheme.cameraMessageSurface,
                foundationTheme.cameraMessageSurface
            ),
            (
                "cameraMessagePrimaryText",
                appTheme.cameraMessagePrimaryText,
                foundationTheme.cameraMessagePrimaryText
            ),
            (
                "cameraMessageSecondaryText",
                appTheme.cameraMessageSecondaryText,
                foundationTheme.cameraMessageSecondaryText
            ),
            (
                "buttonPrimaryGradientStart",
                appTheme.buttonPrimaryGradientStart,
                foundationTheme.buttonPrimaryGradientStart
            ),
            (
                "buttonPrimaryGradientEnd",
                appTheme.buttonPrimaryGradientEnd,
                foundationTheme.buttonPrimaryGradientEnd
            ),
            (
                "buttonPrimaryForeground",
                appTheme.buttonPrimaryForeground,
                foundationTheme.buttonPrimaryForeground
            ),
            (
                "buttonSecondaryFill",
                appTheme.buttonSecondaryFill,
                foundationTheme.buttonSecondaryFill
            ),
            (
                "buttonSecondaryForeground",
                appTheme.buttonSecondaryForeground,
                foundationTheme.buttonSecondaryForeground
            ),
            (
                "buttonTertiaryForeground",
                appTheme.buttonTertiaryForeground,
                foundationTheme.buttonTertiaryForeground
            ),
            ("inputFill", appTheme.inputFill, foundationTheme.inputFill),
            ("inputFocusedFill", appTheme.inputFocusedFill, foundationTheme.inputFocusedFill),
            ("inputForeground", appTheme.inputForeground, foundationTheme.inputForeground),
            ("inputPlaceholder", appTheme.inputPlaceholder, foundationTheme.inputPlaceholder),
            ("inputHelperText", appTheme.inputHelperText, foundationTheme.inputHelperText),
            ("ambientShadowTint", appTheme.ambientShadowTint, foundationTheme.ambientShadowTint)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
            for (name, appColor, foundationColor) in mappings {
                XCTAssertEqual(
                    UIColor(appColor).resolvedColor(with: traits),
                    UIColor(foundationColor).resolvedColor(with: traits),
                    "\(name) \(interfaceStyle)"
                )
            }
        }
    }

    func testAppThemeForwardsEveryHibiLensPolicyAndDepthMethod() {
        let appTheme = AppTheme()
        let foundationTheme = HibiLensBaseTheme()

        XCTAssertEqual(
            appTheme.usesExplicitDividersByDefault,
            foundationTheme.usesExplicitDividersByDefault
        )
        XCTAssertEqual(
            appTheme.prefersTonalLayeringOverShadows,
            foundationTheme.prefersTonalLayeringOverShadows
        )
        XCTAssertEqual(
            appTheme.allowsStandardIOSShadows,
            foundationTheme.allowsStandardIOSShadows
        )
        XCTAssertEqual(appTheme.ambientShadowRadius, foundationTheme.ambientShadowRadius)
        XCTAssertEqual(appTheme.ambientShadowYOffset, foundationTheme.ambientShadowYOffset)

        for depth in HibiLensSurfaceDepth.allCases {
            for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
                XCTAssertEqual(
                    UIColor(appTheme.surfaceColor(for: depth)).resolvedColor(with: traits),
                    UIColor(foundationTheme.surfaceColor(for: depth)).resolvedColor(with: traits),
                    "\(depth) \(interfaceStyle)"
                )
            }
            XCTAssertEqual(
                appTheme.shouldUseAmbientShadow(for: depth),
                foundationTheme.shouldUseAmbientShadow(for: depth),
                "\(depth)"
            )
        }
    }

    func testAppTypographyCompatibilityUsesHibiLensPolicy() {
        XCTAssertEqual(
            AppTypography.japaneseLineHeightDefaultMultiplier,
            HibiLensTypography.contentLineHeightDefaultMultiplier
        )
        XCTAssertEqual(
            AppTypography.lineSpacing(for: 20),
            HibiLensTypography.contentLineSpacing(for: 20)
        )
    }

    func testAppSurfaceDepthCompatibilityMapsToHibiLensPolicy() {
        let appTheme = AppTheme()
        let foundationTheme = HibiLensBaseTheme()
        let mappings: [(AppTheme.SurfaceDepth, HibiLensSurfaceDepth)] = [
            (.base, .base),
            (.section, .section),
            (.card, .card),
            (.elevated, .elevated)
        ]

        for (appDepth, foundationDepth) in mappings {
            XCTAssertEqual(appDepth.foundationDepth, foundationDepth)
            for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
                XCTAssertEqual(
                    UIColor(appTheme.surfaceColor(for: appDepth)).resolvedColor(with: traits),
                    UIColor(foundationTheme.surfaceColor(for: foundationDepth)).resolvedColor(with: traits)
                )
            }
            XCTAssertEqual(
                appTheme.shouldUseAmbientShadow(for: appDepth),
                foundationTheme.shouldUseAmbientShadow(for: foundationDepth)
            )
        }
    }

    func testAppThemePreservesProductAccentAliases() {
        let theme = AppTheme()
        let mappings: [(String, Color, HibiLensAdaptiveColorToken)] = [
            ("accentPrimaryMuted", theme.accentPrimaryMuted, HibiLensPalette.primaryAccentDeep),
            ("lensMuted", theme.lensMuted, HibiLensPalette.primaryAccentMuted),
            ("discoveryAccent", theme.discoveryAccent, HibiLensPalette.secondaryAccent),
            ("discoveryMuted", theme.discoveryMuted, HibiLensPalette.secondaryAccentMuted)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
            for (name, appColor, foundationToken) in mappings {
                XCTAssertEqual(
                    UIColor(appColor).resolvedColor(with: traits),
                    foundationToken.uiColor.resolvedColor(with: traits),
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
