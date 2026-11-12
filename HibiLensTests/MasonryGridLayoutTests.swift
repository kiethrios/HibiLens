import XCTest
@testable import HibiLens

final class MasonryGridLayoutTests: XCTestCase {
    func testAdaptiveColumnsFollowAvailableWidth() {
        for (width, expected) in [(150.0, 1), (352.0, 2), (629.0, 3), (850.0, 4)] {
            XCTAssertEqual(
                MasonryGridLayout.adaptiveColumnCount(width: width, minimumWidth: 160, spacing: 16),
                expected
            )
        }
    }

    func testAdaptiveColumnsRespectThresholdAndLargerType() {
        XCTAssertEqual(MasonryGridLayout.adaptiveColumnCount(width: 511, minimumWidth: 160, spacing: 16), 2)
        XCTAssertEqual(MasonryGridLayout.adaptiveColumnCount(width: 512, minimumWidth: 160, spacing: 16), 3)
        XCTAssertEqual(MasonryGridLayout.adaptiveColumnCount(width: 629, minimumWidth: 240, spacing: 16), 2)
    }

    func testFirstRowStartsBothColumnsAtSameTop() {
        let placements = MasonryGridPlacementCalculator.placements(
            itemHeights: [120, 180],
            columnCount: 2,
            columnWidth: 100,
            spacing: 16
        )

        XCTAssertEqual(placements.map(\.column), [0, 1])
        XCTAssertEqual(placements.map(\.y), [0, 0])
    }

    func testItemsCycleLeftToRightRegardlessOfColumnHeight() {
        let placements = MasonryGridPlacementCalculator.placements(
            itemHeights: [200, 80, 120, 90],
            columnCount: 2,
            columnWidth: 100,
            spacing: 10
        )

        XCTAssertEqual(placements.map(\.column), [0, 1, 0, 1])
        XCTAssertEqual(placements.map(\.y), [0, 0, 210, 90])
    }

    func testMeasuredHeightExcludesTrailingSpacing() {
        let height = MasonryGridPlacementCalculator.measuredHeight(
            itemHeights: [200, 80, 120],
            columnCount: 2,
            spacing: 10
        )

        XCTAssertEqual(height, 330)
    }
}
