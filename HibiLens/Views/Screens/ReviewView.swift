import SwiftUI
import SwiftData

struct ReviewView: View {
    private enum ReviewLayout {
        static let columnCount = ReviewVisualRefillSpec.columnCount
        static let columnSpacing = ReviewVisualRefillSpec.columnSpacing
        static let segmentedControlHeight = ReviewVisualRefillSpec.segmentedControlHeight
        static let segmentedControlMaxWidth = ReviewVisualRefillSpec.segmentedControlMaxWidth
        static let emptyStateMinHeight: CGFloat = 360
        static let emptyStateFrameHeight: CGFloat = 236
        static let topScrollClearance = segmentedControlHeight + AppLayout.reviewFloatingControlTopInset + AppLayout.bottomNavContentInset
        static let bottomScrollClearance = AppLayout.bottomNavBarHeight + AppLayout.bottomNavContentInset
    }

    private enum ReviewTab: CaseIterable, Identifiable, Hashable {
        case learning
        case mastered

        var title: String {
            switch self {
            case .learning:
                ReviewVisualRefillSpec.learningTabTitle
            case .mastered:
                ReviewVisualRefillSpec.masteredTabTitle
            }
        }

        var emptyTitle: String {
            switch self {
            case .learning:
                ReviewVisualRefillSpec.learningEmptyTitle
            case .mastered:
                ReviewVisualRefillSpec.masteredEmptyTitle
            }
        }

        var emptyMessage: String {
            switch self {
            case .learning:
                ReviewVisualRefillSpec.learningEmptyMessage
            case .mastered:
                ReviewVisualRefillSpec.masteredEmptyMessage
            }
        }

        var id: String { title }
    }

    private let theme = AppTheme()

    let onOpenCard: (CaptureItem, [CaptureItem], VocabularyDetailSource) -> Void
    let transitionNamespace: Namespace.ID?

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: ReviewTab = .learning
    @State private var isDeleteModeActive = false
    @State private var cardPendingDeletion: VocabularyCard?
    @Query(sort: \VocabularyCard.capturedAt, order: .reverse) private var cards: [VocabularyCard]

    init(
        onOpenCard: @escaping (CaptureItem, [CaptureItem], VocabularyDetailSource) -> Void = { _, _, _ in },
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.onOpenCard = onOpenCard
        self.transitionNamespace = transitionNamespace
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(ReviewTab.allCases) { tab in
                reviewPage(for: tab)
                    .tag(tab)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .overlay(alignment: .top) {
            topFloatingSegmentedControl
        }
        .alert(ReviewVisualRefillSpec.deleteAlertTitle, isPresented: deleteConfirmationBinding) {
            Button(AppL10n.Common.cancel, role: .cancel) {
                cardPendingDeletion = nil
            }

            Button(ReviewVisualRefillSpec.deleteConfirmTitle, role: .destructive) {
                confirmDeletion()
            }
        }
    }

    private func reviewPage(for tab: ReviewTab) -> some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissDeleteModeIfNeeded(for: .background)
                        }

                    reviewColumns(for: tab)
                        .appScreenPadding(
                            top: ReviewLayout.topScrollClearance,
                            bottom: ReviewLayout.bottomScrollClearance
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .onAppear {
            CapturePerformanceLog.mark("review.page.appear.\(tab.title.lowercased())")
        }
    }

    private var topFloatingSegmentedControl: some View {
        segmentedControl
            .padding(.top, AppLayout.reviewFloatingControlTopInset)
            .padding(.horizontal, AppLayout.reviewFloatingControlHorizontalInset)
            .frame(maxWidth: .infinity)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ReviewTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        dismissDeleteModeIfNeeded(for: .segmentedControl)
                    }
                } label: {
                    Text(tab.title)
                        .font(AppTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(tab == selectedTab ? theme.primaryText : theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                        .background {
                            if tab == selectedTab {
                                Capsule()
                                    .fill(theme.lensMuted.opacity(0.72))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(maxWidth: ReviewLayout.segmentedControlMaxWidth)
        .frame(height: ReviewLayout.segmentedControlHeight)
        .modifier(ReviewSegmentedControlGlassSurface(theme: theme))
        .overlay {
            Capsule()
                .stroke(theme.lensAccent.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .appAmbientDepth(theme: theme, depth: .elevated, yOffset: 4)
        .frame(maxWidth: .infinity)
    }

    private func reviewColumns(for tab: ReviewTab) -> some View {
        let reviewCards = cards(for: tab)
        let items = reviewCards.map { $0.captureItem() }
        let source = source(for: tab)

        return Group {
            if reviewCards.isEmpty {
                reviewEmptyState(for: tab)
            } else {
                MasonryGridLayout(columnCount: ReviewLayout.columnCount, spacing: ReviewLayout.columnSpacing) {
                    ForEach(reviewCards) { card in
                        let item = card.captureItem()

                        VocabularyReviewCard(
                            item: item,
                            onTap: { onOpenCard(item, items, source) },
                            isDeleteModeActive: isDeleteModeActive,
                            onLongPress: enterDeleteMode,
                            onDelete: { cardPendingDeletion = card },
                            transitionNamespace: transitionNamespace
                        )
                    }
                }
            }
        }
    }

    private func reviewEmptyState(for tab: ReviewTab) -> some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius, style: .continuous)
                    .fill(theme.keepsakeCard)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.lensMuted.opacity(0.72))
                            .frame(width: 58, height: 58)

                        Image(systemName: "camera")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(theme.lensAccent)
                    }

                    VStack(spacing: 8) {
                        Text(tab.emptyTitle)
                            .font(AppTypography.titleMedium.weight(.semibold))
                            .foregroundStyle(theme.primaryText)
                            .multilineTextAlignment(.center)

                        Text(tab.emptyMessage)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 28)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: ReviewLayout.emptyStateFrameHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: ReviewLayout.emptyStateMinHeight, alignment: .center)
    }

    private func cards(for tab: ReviewTab) -> [VocabularyCard] {
        switch tab {
        case .learning:
            cards.filter { $0.matchesReviewBucket(.learned) }
        case .mastered:
            cards.filter { $0.matchesReviewBucket(.mastered) }
        }
    }

    private func source(for tab: ReviewTab) -> VocabularyDetailSource {
        switch tab {
        case .learning:
            .learningReview
        case .mastered:
            .masteredReview
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            cardPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                cardPendingDeletion = nil
            }
        }
    }

    private func enterDeleteMode() {
        guard !isDeleteModeActive else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            isDeleteModeActive = true
        }
    }

    private func confirmDeletion() {
        guard let card = cardPendingDeletion else { return }

        ReviewCardDeletion.delete(card, in: modelContext)
        cardPendingDeletion = nil
    }

    private func dismissDeleteModeIfNeeded(for target: ReviewDeleteModeDismissal.TapTarget) {
        guard ReviewDeleteModeDismissal.shouldDismiss(
            isDeleteModeActive: isDeleteModeActive,
            target: target
        ) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            isDeleteModeActive = false
            cardPendingDeletion = nil
        }
    }

}

private struct ReviewSegmentedControlGlassSurface: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(theme.glassShellTint), in: .capsule)
        } else {
            content.background(
                Capsule()
                    .fill(theme.surfaceBase.opacity(0.7))
                    .background(.ultraThinMaterial, in: Capsule())
            )
        }
    }
}

#Preview {
    ReviewView()
        .background(AppTheme().background)
        .modelContainer(PreviewModelContainer.shared)
}
