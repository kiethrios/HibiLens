import SwiftUI

struct MasonryGridPlacement: Equatable {
    let index: Int
    let column: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

enum MasonryGridPlacementCalculator {
    static func placements(
        itemHeights: [CGFloat],
        columnCount: Int,
        columnWidth: CGFloat,
        spacing: CGFloat
    ) -> [MasonryGridPlacement] {
        guard columnCount > 0 else { return [] }

        var columnHeights = Array(repeating: CGFloat.zero, count: columnCount)

        return itemHeights.enumerated().map { index, itemHeight in
            let column = index % columnCount
            let x = CGFloat(column) * (columnWidth + spacing)
            let y = columnHeights[column]

            columnHeights[column] += itemHeight + spacing

            return MasonryGridPlacement(
                index: index,
                column: column,
                x: x,
                y: y,
                width: columnWidth,
                height: itemHeight
            )
        }
    }

    static func measuredHeight(
        itemHeights: [CGFloat],
        columnCount: Int,
        spacing: CGFloat
    ) -> CGFloat {
        placements(
            itemHeights: itemHeights,
            columnCount: columnCount,
            columnWidth: 0,
            spacing: spacing
        )
        .map { $0.y + $0.height }
        .max() ?? 0
    }

}

struct MasonryGridLayout: Layout {
    let columnCount: Int
    private let minimumColumnWidth: CGFloat?
    let spacing: CGFloat

    init(columnCount: Int = 2, spacing: CGFloat) {
        self.columnCount = max(1, columnCount)
        self.minimumColumnWidth = nil
        self.spacing = spacing
    }

    init(minimumColumnWidth: CGFloat, spacing: CGFloat) {
        self.columnCount = 1
        self.minimumColumnWidth = max(1, minimumColumnWidth)
        self.spacing = spacing
    }

    static func adaptiveColumnCount(width: CGFloat, minimumWidth: CGFloat, spacing: CGFloat) -> Int {
        guard width.isFinite, minimumWidth > 0, spacing >= 0 else { return 1 }
        return max(1, Int(floor((max(0, width) + spacing) / (minimumWidth + spacing))))
    }

    private func columns(for width: CGFloat) -> Int {
        guard let minimumColumnWidth else { return columnCount }
        return Self.adaptiveColumnCount(width: width, minimumWidth: minimumColumnWidth, spacing: spacing)
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else {
            return CGSize(width: proposal.width ?? 0, height: 0)
        }

        let width = proposal.width ?? 0
        let columnCount = columns(for: width)
        let columnWidth = columnWidth(for: width)
        let itemHeights = subviews.map { subview in
            subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            ).height
        }

        return CGSize(
            width: width,
            height: MasonryGridPlacementCalculator.measuredHeight(
                itemHeights: itemHeights,
                columnCount: columnCount,
                spacing: spacing
            )
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let columnCount = columns(for: bounds.width)
        let columnWidth = columnWidth(for: bounds.width)
        let itemHeights = subviews.map { subview in
            subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            ).height
        }
        let placements = MasonryGridPlacementCalculator.placements(
            itemHeights: itemHeights,
            columnCount: columnCount,
            columnWidth: columnWidth,
            spacing: spacing
        )

        for placement in placements {
            subviews[placement.index].place(
                at: CGPoint(
                    x: bounds.minX + placement.x,
                    y: bounds.minY + placement.y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: placement.width,
                    height: placement.height
                )
            )
        }
    }

    private func columnWidth(for availableWidth: CGFloat) -> CGFloat {
        let columnCount = columns(for: availableWidth)
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        return max(0, (availableWidth - totalSpacing) / CGFloat(columnCount))
    }
}
