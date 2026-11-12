import XCTest
@testable import HibiLens

final class HomeVisualRefillTests: XCTestCase {
    func testHomeVisualRefillUsesApprovedDiscoveryAnatomy() {
        XCTAssertEqual(HomeVisualRefillSpec.discoveryTitle, "Today's Discovery")
        XCTAssertEqual(HomeVisualRefillSpec.primaryCaptureActionTitle, "Capture Now")
        XCTAssertEqual(HomeVisualRefillSpec.keepsakesSectionTitle, "Your Keepsakes")
        XCTAssertEqual(HomeVisualRefillSpec.seeAllActionTitle, "See All")
        XCTAssertEqual(HomeVisualRefillSpec.statsSectionTitle, "Progress")
    }

    func testHomeVisualRefillKeepsCaptureAndStatsHierarchy() {
        XCTAssertGreaterThanOrEqual(
            HomeVisualRefillSpec.dailyDiscoveryHeroHeight,
            AppLayout.dailyDiscoveryMinHeight
        )
        XCTAssertLessThanOrEqual(
            HomeVisualRefillSpec.dailyDiscoveryHeroHeight,
            AppLayout.dailyDiscoveryMaxHeight
        )
        XCTAssertGreaterThan(HomeVisualRefillSpec.lensButtonDiameter, AppLayout.compactCaptureIconDiameter)
        XCTAssertLessThan(HomeVisualRefillSpec.statCardMinHeight, HomeVisualRefillSpec.dailyDiscoveryHeroHeight)
    }

    func testStatisticMetricCardRendersStoredLocalizedCopy() throws {
        let source = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/HomeView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Text(metric.title)"))
        XCTAssertTrue(source.contains("if let subtitle = metric.subtitle"))
        XCTAssertTrue(source.contains("Text(subtitle)"))
    }

    func testEmptyKeepsakeCopyWrapsWithinTheCaptureFrame() throws {
        let source = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/HomeView.swift"),
            encoding: .utf8
        )
        let componentStart = try XCTUnwrap(source.range(of: "private struct EmptyKeepsakeSlot"))
        let componentEnd = try XCTUnwrap(
            source.range(of: "private struct LensCaptureButton", range: componentStart.upperBound..<source.endIndex)
        )
        let componentSource = String(source[componentStart.lowerBound..<componentEnd.lowerBound])

        XCTAssertTrue(source.contains("static let emptyKeepsakeTextMaxWidth: CGFloat = 112"))
        XCTAssertTrue(componentSource.contains(".lineLimit(2)"))
        XCTAssertTrue(componentSource.contains(".fixedSize(horizontal: false, vertical: true)"))
        XCTAssertTrue(
            componentSource.contains(".frame(maxWidth: HomeVisualRefillSpec.emptyKeepsakeTextMaxWidth)")
        )
    }

    func testHomeKeepsakeRowCardsUseFlatTonalSurfaces() throws {
        let captureCardSource = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Components/CaptureCard.swift"),
            encoding: .utf8
        )
        let homeSource = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/HomeView.swift"),
            encoding: .utf8
        )
        let sampleStart = try XCTUnwrap(homeSource.range(of: "private struct SampleKeepsakeCard"))
        let sampleEnd = try XCTUnwrap(
            homeSource.range(of: "private struct StatisticMetricCard", range: sampleStart.upperBound..<homeSource.endIndex)
        )
        let sampleSource = String(homeSource[sampleStart.lowerBound..<sampleEnd.lowerBound])

        XCTAssertFalse(captureCardSource.contains(".appKeepsakeCardSurface("))
        XCTAssertTrue(captureCardSource.contains(".appCardSurface("))
        XCTAssertTrue(captureCardSource.contains("depth: .card"))
        XCTAssertFalse(sampleSource.contains(".appKeepsakeCardSurface("))
        XCTAssertTrue(sampleSource.contains(".appCardSurface("))
        XCTAssertTrue(sampleSource.contains("depth: .card"))
    }

    func testReviewVisualRefillUsesApprovedGalleryCopy() {
        XCTAssertEqual(ReviewVisualRefillSpec.learningTabTitle, "Learning")
        XCTAssertEqual(ReviewVisualRefillSpec.masteredTabTitle, "Mastered")
        XCTAssertEqual(ReviewVisualRefillSpec.learningEmptyTitle, "No learning cards yet.")
        XCTAssertEqual(
            ReviewVisualRefillSpec.learningEmptyMessage,
            "Captured words you are learning will appear here."
        )
        XCTAssertEqual(ReviewVisualRefillSpec.masteredEmptyTitle, "No mastered cards yet.")
        XCTAssertEqual(
            ReviewVisualRefillSpec.masteredEmptyMessage,
            "Cards you master will collect here."
        )
        XCTAssertEqual(ReviewVisualRefillSpec.deleteAlertTitle, "Delete this card?")
        XCTAssertEqual(ReviewVisualRefillSpec.deleteConfirmTitle, "Delete")
    }

    func testReviewVisualRefillKeepsMasonryScaleAndCompactFilter() {
        XCTAssertEqual(ReviewVisualRefillSpec.minimumCardWidth, 160)
        XCTAssertEqual(ReviewVisualRefillSpec.columnSpacing, 16)
        XCTAssertEqual(ReviewVisualRefillSpec.segmentedControlHeight, 48)
        XCTAssertEqual(ReviewVisualRefillSpec.segmentedControlMaxWidth, 384)
        XCTAssertLessThanOrEqual(
            ReviewVisualRefillSpec.cardCornerRadius,
            AppLayout.keepsakeCardCornerRadius
        )
        XCTAssertGreaterThan(
            ReviewVisualRefillSpec.imageMaxHeight,
            ReviewVisualRefillSpec.imageMinHeight
        )
    }

    func testReviewContentScrollsBehindTabBarWithBottomClearance() throws {
        let source = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/ReviewView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(
            source.contains(
                "static let bottomScrollClearance = AppLayout.bottomNavContentInset"
            )
        )
        XCTAssertTrue(source.contains(".ignoresSafeArea(.container, edges: .vertical)"))
        XCTAssertTrue(source.contains("bottom: ReviewLayout.bottomScrollClearance + safeAreaInsets.bottom"))
    }

    func testBottomNavigationUsesUncompoundedInactiveForeground() throws {
        let source = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Components/BottomNavBar.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".foregroundStyle(isActive ? theme.primaryText : theme.navigationInactiveText)"))
        XCTAssertFalse(source.contains("theme.cardSecondaryText.opacity(0.78)"))
        XCTAssertFalse(source.contains(".opacity(isActive ? 1 : 0.78)"))
    }

    func testGallerySurfacesDoNotRenderViewfinderCornerSquares() throws {
        let paths = [
            "HibiLens/Views/Screens/HomeView.swift",
            "HibiLens/Views/Screens/ReviewView.swift",
            "HibiLens/Views/Components/CaptureCard.swift",
            "HibiLens/Views/Components/VocabularyReviewCard.swift"
        ]

        for path in paths {
            let source = try String(
                contentsOf: projectRoot().appendingPathComponent(path),
                encoding: .utf8
            )

            XCTAssertFalse(source.contains(".appViewfinderCorners("), path)
            XCTAssertFalse(source.contains("HomeViewfinderCorners(color:"), path)
        }
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
