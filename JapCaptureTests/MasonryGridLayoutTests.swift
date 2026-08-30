import XCTest
@testable import JapCapture

final class MasonryGridLayoutTests: XCTestCase {
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

    func testNextItemUsesCurrentlyShorterColumn() {
        let placements = MasonryGridPlacementCalculator.placements(
            itemHeights: [200, 80, 120, 90],
            columnCount: 2,
            columnWidth: 100,
            spacing: 10
        )

        XCTAssertEqual(placements.map(\.column), [0, 1, 1, 0])
        XCTAssertEqual(placements.map(\.y), [0, 0, 90, 210])
    }

    func testMeasuredHeightExcludesTrailingSpacing() {
        let height = MasonryGridPlacementCalculator.measuredHeight(
            itemHeights: [200, 80, 120],
            columnCount: 2,
            spacing: 10
        )

        XCTAssertEqual(height, 210)
    }
}
