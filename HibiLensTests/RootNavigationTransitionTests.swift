import XCTest
@testable import HibiLens

final class RootNavigationTransitionTests: XCTestCase {
    func testDirectionFollowsVisibleBottomNavigationOrder() {
        XCTAssertEqual(
            RootNavigationTransitionDirection(from: .home, to: .review),
            .forward
        )
        XCTAssertEqual(
            RootNavigationTransitionDirection(from: .review, to: .personal),
            .forward
        )
        XCTAssertEqual(
            RootNavigationTransitionDirection(from: .personal, to: .home),
            .backward
        )
    }

    func testDirectJumpUsesOneResolvedDirection() {
        XCTAssertEqual(
            RootNavigationTransitionDirection(from: .home, to: .personal),
            .forward
        )
        XCTAssertEqual(
            RootNavigationTransitionDirection(from: .personal, to: .home),
            .backward
        )
    }

    func testDirectionRejectsCaptureAndRepeatedSelection() {
        XCTAssertNil(RootNavigationTransitionDirection(from: .home, to: .home))
        XCTAssertNil(RootNavigationTransitionDirection(from: .home, to: .capture))
        XCTAssertNil(RootNavigationTransitionDirection(from: .capture, to: .home))
    }

    func testContentViewUsesTapDrivenDirectionalRootTransition() throws {
        let source = try String(
            contentsOf: projectRoot().appendingPathComponent("HibiLens/Views/Screens/ContentView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("selectRootDestination(destination)"))
        XCTAssertTrue(source.contains("withAnimation(AppMotion.rootNavigationAnimation)"))
        XCTAssertTrue(source.contains(".id(activeDestination.id)"))
        XCTAssertTrue(source.contains(".transition(rootContentTransition)"))
        XCTAssertTrue(source.contains("accessibilityReduceMotion"))
        XCTAssertTrue(source.contains("return .opacity"))
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
