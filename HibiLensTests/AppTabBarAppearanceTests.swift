import UIKit
import XCTest
@testable import HibiLens

final class AppTabBarAppearanceTests: XCTestCase {
    func testHibiLensPaletteResolvesSemanticColorsForLightAndDark() {
        let palette = AppTabBarPalette.hibiLens

        assert(palette.surface, matches: AppColorToken.galleryBackground.day.uiColor, alpha: 0.82, style: .light)
        assert(palette.surface, matches: AppColorToken.galleryBand.dark.uiColor, alpha: 0.88, style: .dark)
        assert(palette.selectedForeground, matches: AppColorToken.lensAccent.day.uiColor, style: .light)
        assert(palette.selectedForeground, matches: AppColorToken.lensAccent.dark.uiColor, style: .dark)
        assert(palette.selectedFill, matches: AppColorToken.lensMuted.day.uiColor, alpha: 0.72, style: .light)
        assert(palette.selectedFill, matches: AppColorToken.lensMuted.dark.uiColor, alpha: 0.72, style: .dark)
        assert(palette.inactiveForeground, matches: AppColorToken.navigationInactive.day.uiColor, style: .light)
        assert(palette.inactiveForeground, matches: AppColorToken.navigationInactive.dark.uiColor, style: .dark)
    }

    func testMakeAppliesAdaptiveBackgroundBlurAndSelectionFill() {
        let palette = AppTabBarPalette.hibiLens
        let appearance = AppTabBarAppearance.make(palette: palette)

        assert(appearance.backgroundColor, matches: AppColorToken.galleryBackground.day.uiColor, alpha: 0.82, style: .light)
        XCTAssertNotNil(appearance.backgroundEffect)
        assert(appearance.selectionIndicatorTintColor, matches: AppColorToken.lensMuted.dark.uiColor, alpha: 0.72, style: .dark)
    }

    func testAllItemLayoutsUsePaletteForegrounds() {
        let palette = AppTabBarPalette.hibiLens
        let appearance = AppTabBarAppearance.make(palette: palette)

        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            assert(layout.normal.iconColor, matches: AppColorToken.navigationInactive.dark.uiColor, style: .dark)
            assert(layout.normal.titleTextAttributes[.foregroundColor] as? UIColor, matches: AppColorToken.navigationInactive.day.uiColor, style: .light)
            assert(layout.selected.iconColor, matches: AppColorToken.lensAccent.dark.uiColor, style: .dark)
            assert(layout.selected.titleTextAttributes[.foregroundColor] as? UIColor, matches: AppColorToken.lensAccent.day.uiColor, style: .light)
        }
    }

    func testApplyInstallsAppearancesAndFallbackTints() {
        let palette = AppTabBarPalette.hibiLens
        let tabBar = UITabBar()

        AppTabBarAppearance.apply(palette: palette, to: tabBar)

        XCTAssertNotNil(tabBar.standardAppearance)
        XCTAssertNotNil(tabBar.scrollEdgeAppearance)
        assert(tabBar.tintColor, matches: AppColorToken.lensAccent.dark.uiColor, style: .dark)
        assert(tabBar.unselectedItemTintColor, matches: AppColorToken.navigationInactive.day.uiColor, style: .light)
    }

    private func assert(
        _ actual: UIColor?,
        matches expected: UIColor,
        alpha: CGFloat = 1,
        style: UIUserInterfaceStyle,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual else {
            XCTFail("Expected a color", file: file, line: line)
            return
        }
        let traits = UITraitCollection(userInterfaceStyle: style)
        let resolvedActual = actual.resolvedColor(with: traits)
        let resolvedExpected = expected.resolvedColor(with: traits)
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0
        XCTAssertTrue(resolvedActual.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha), file: file, line: line)
        XCTAssertTrue(resolvedExpected.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha), file: file, line: line)
        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(actualAlpha, expectedAlpha * alpha, accuracy: 0.01, file: file, line: line)
    }
}
