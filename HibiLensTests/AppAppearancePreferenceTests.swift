import SwiftUI
import XCTest
@testable import HibiLens

final class AppAppearancePreferenceTests: XCTestCase {
    func testAppearancePreferenceUsesStableRawValuesAndSystemDefault() {
        XCTAssertEqual(AppAppearancePreference.system.rawValue, "system")
        XCTAssertEqual(AppAppearancePreference.day.rawValue, "day")
        XCTAssertEqual(AppAppearancePreference.dark.rawValue, "dark")
        XCTAssertEqual(AppAppearancePreference.defaultValue, .system)
        XCTAssertEqual(AppAppearancePreference.storageKey, "app.appearance.preference")
    }

    func testAppearancePreferenceFallsBackForMissingOrUnknownValues() {
        XCTAssertEqual(AppAppearancePreference.resolve(rawValue: nil), .system)
        XCTAssertEqual(AppAppearancePreference.resolve(rawValue: ""), .system)
        XCTAssertEqual(AppAppearancePreference.resolve(rawValue: "obsolete"), .system)
        XCTAssertEqual(AppAppearancePreference.resolve(rawValue: "day"), .day)
        XCTAssertEqual(AppAppearancePreference.resolve(rawValue: "dark"), .dark)
    }

    func testAppearancePreferenceMapsToPreferredColorScheme() {
        XCTAssertNil(AppAppearancePreference.system.preferredColorScheme)
        XCTAssertEqual(AppAppearancePreference.day.preferredColorScheme, .light)
        XCTAssertEqual(AppAppearancePreference.dark.preferredColorScheme, .dark)
    }

    func testAppearancePreferenceCaseOrderMatchesMenuOrder() {
        XCTAssertEqual(AppAppearancePreference.allCases, [.system, .day, .dark])
    }
}
