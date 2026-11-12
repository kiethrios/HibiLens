import XCTest
@testable import HibiLens

final class RootTabNavigationTests: XCTestCase {
    func testContentViewUsesThreeSystemRootTabs() throws {
        let source = try contentViewSource()

        XCTAssertTrue(source.contains("TabView(selection: $activeDestination)"))
        XCTAssertEqual(source.components(separatedBy: ".tabItem {").count - 1, 3)
        XCTAssertTrue(source.contains(".tag(NavDestination.home)"))
        XCTAssertTrue(source.contains(".tag(NavDestination.review)"))
        XCTAssertTrue(source.contains(".tag(NavDestination.personal)"))
        XCTAssertTrue(source.contains(".tint(theme.lensAccent)"))
        XCTAssertFalse(source.contains("BottomNavScreen("))
        XCTAssertFalse(source.contains("rootContentTransition"))
    }

    func testEachRootTabOwnsANavigationStack() throws {
        let source = try contentViewSource()

        XCTAssertEqual(source.components(separatedBy: "NavigationStack").count - 1, 3)
    }

    func testCaptureRouteHidesTheSystemTabBar() throws {
        let source = try contentViewSource()

        XCTAssertTrue(source.contains("CaptureView()"))
        XCTAssertTrue(source.contains(".toolbar(.hidden, for: .tabBar)"))
    }

    func testCardDetailsUseNativeDestinationsInsteadOfRootOverlay() throws {
        let source = try contentViewSource()
        XCTAssertTrue(source.contains("case vocabularyDetail(VocabularyDetailSession)"))
        XCTAssertTrue(source.contains("NavigationStack(path: $reviewPath)"))
        XCTAssertFalse(source.contains("VocabularyDetailTransitionOverlay"))
        XCTAssertFalse(source.contains("activeVocabularyDetailPresentation"))
    }

    func testSplitDetailCloseUsesTheContainerSystemToolbar() throws {
        let source = try String(contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/ReviewView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("ToolbarItem(placement: .cancellationAction)"))
        XCTAssertFalse(source.contains("extendsIntoSafeArea:"))
    }

    func testDetailDoesNotDrawItsOwnBackButtonOrIgnoreContainerSafeArea() throws {
        let source = try String(contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Components/ExpandedVocabularyDetailView.swift"), encoding: .utf8)
        XCTAssertFalse(source.contains("BackGlassButton("))
        XCTAssertFalse(source.contains(".ignoresSafeArea("))
    }

    func testApplicationInstallsSystemTabBarThemeAtStartup() throws {
        let source = try appSource()
        XCTAssertTrue(source.contains("init()"))
        XCTAssertTrue(source.contains("AppTabBarAppearance.apply()"))
    }

    private func contentViewSource() throws -> String {
        try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/ContentView.swift"),
            encoding: .utf8
        )
    }

    private func appSource() throws -> String {
        try String(contentsOf: projectRoot().appendingPathComponent("HibiLens/App/HibiLensApp.swift"), encoding: .utf8)
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
