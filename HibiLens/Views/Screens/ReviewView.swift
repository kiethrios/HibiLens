import SwiftUI
import SwiftData

struct ReviewView: View {
    private enum ReviewLayout {
        static let columnSpacing = ReviewVisualRefillSpec.columnSpacing
        static let emptyStateMinHeight: CGFloat = 360
        static let emptyStateFrameHeight: CGFloat = 236
        static let topScrollClearance: CGFloat = AppLayout.screenTopPadding + 48
        static let bottomScrollClearance = AppLayout.bottomNavContentInset
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
    @ScaledMetric(relativeTo: .body)
    private var minimumCardWidth = ReviewVisualRefillSpec.minimumCardWidth
    @State private var selectedTab: ReviewTab = .learning
    @State private var isDeleteModeActive = false
    @State private var cardPendingDeletion: VocabularyCard?
    @State private var detailSession: VocabularyDetailSession?
    @State private var highlightedCardID: UUID?
    @State private var allowsSplitDetail = false
    @Query(sort: \VocabularyCard.capturedAt, order: .reverse) private var cards: [VocabularyCard]

    init(
        onOpenCard: @escaping (CaptureItem, [CaptureItem], VocabularyDetailSource) -> Void = { _, _, _ in },
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.onOpenCard = onOpenCard
        self.transitionNamespace = transitionNamespace
    }

    var body: some View {
        GeometryReader { geometry in
            let supportsSplit = geometry.size.width >= 760 && geometry.size.width > geometry.size.height
            HStack(spacing: 0) {
                reviewBrowser(safeAreaInsets: geometry.safeAreaInsets)
                    .frame(maxWidth: .infinity)
                if supportsSplit, let session = detailSession {
                    Divider()
                    ExpandedVocabularyDetailView(
                        session: session,
                        onDismiss: closeSplitDetail,
                        onSelectionChange: { highlightedCardID = $0 }
                    )
                    .id(session.selectedID)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
            }
            .onAppear { allowsSplitDetail = supportsSplit }
            .onChange(of: supportsSplit) { _, supported in
                allowsSplitDetail = supported
                if !supported, let session = detailSession,
                   let item = session.items.first(where: { $0.id == highlightedCardID }) {
                    closeSplitDetail()
                    onOpenCard(item, session.items, session.source)
                }
            }
        }
        .onChange(of: selectedTab) { _, _ in
            closeSplitDetail()
            dismissDeleteModeIfNeeded(for: .segmentedControl)
        }
        .toolbar {
            if detailSession != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppL10n.Common.close, systemImage: "xmark", action: closeSplitDetail)
                }
            }
        }
        .alert(ReviewVisualRefillSpec.deleteAlertTitle, isPresented: deleteConfirmationBinding) {
            Button(AppL10n.Common.cancel, role: .cancel) { cardPendingDeletion = nil }
            Button(ReviewVisualRefillSpec.deleteConfirmTitle, role: .destructive) { confirmDeletion() }
        }
    }

    private func reviewBrowser(safeAreaInsets: EdgeInsets) -> some View {
        TabView(selection: $selectedTab) {
            ForEach(ReviewTab.allCases) { tab in
                reviewPage(for: tab, safeAreaInsets: safeAreaInsets)
                    .tag(tab)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .vertical)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .overlay(alignment: .top) {
            reviewFilter
                .frame(maxWidth: 360)
                .padding(.horizontal, AppLayout.screenHorizontalPadding)
                .padding(.top, AppLayout.screenTopPadding)
        }
    }

    private func reviewPage(for tab: ReviewTab, safeAreaInsets: EdgeInsets) -> some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismissDeleteModeIfNeeded(for: .background)
                            }

                        reviewColumns(for: tab)
                            .appScreenPadding(
                                top: ReviewLayout.topScrollClearance + safeAreaInsets.top,
                                bottom: ReviewLayout.bottomScrollClearance + safeAreaInsets.bottom
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .onChange(of: proxy.size.width) { _, _ in
                    if let highlightedCardID {
                        scrollProxy.scrollTo(highlightedCardID, anchor: .center)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .onAppear {
            CapturePerformanceLog.mark("review.page.appear.\(tab.title.lowercased())")
        }
    }

    private var reviewFilter: some View {
        Picker(AppL10n.Nav.review, selection: $selectedTab) {
            ForEach(ReviewTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private func reviewColumns(for tab: ReviewTab) -> some View {
        let reviewCards = cards(for: tab)
        let items = reviewCards.map { $0.captureItem() }
        let source = source(for: tab)

        return Group {
            if reviewCards.isEmpty {
                reviewEmptyState(for: tab)
            } else {
                MasonryGridLayout(minimumColumnWidth: minimumCardWidth, spacing: ReviewLayout.columnSpacing) {
                    ForEach(reviewCards) { card in
                        let item = card.captureItem()

                        VocabularyReviewCard(
                            item: item,
                            onTap: { openCard(item, items: items, source: source) },
                            isDeleteModeActive: isDeleteModeActive,
                            onLongPress: enterDeleteMode,
                            onDelete: { cardPendingDeletion = card },
                            transitionNamespace: transitionNamespace
                        )
                        .overlay {
                            if highlightedCardID == item.id {
                                RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius)
                                    .stroke(theme.lensAccent, lineWidth: 2)
                                    .allowsHitTesting(false)
                            }
                        }
                        .id(item.id)
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

    private func openCard(_ item: CaptureItem, items: [CaptureItem], source: VocabularyDetailSource) {
        guard allowsSplitDetail else {
            onOpenCard(item, items, source)
            return
        }
        highlightedCardID = item.id
        detailSession = VocabularyDetailSession(selected: item, in: items, source: source)
    }

    private func closeSplitDetail() {
        detailSession = nil
        highlightedCardID = nil
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
        if highlightedCardID == card.id { closeSplitDetail() }
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

#Preview {
    ReviewView()
        .background(AppTheme().background)
        .modelContainer(PreviewModelContainer.shared)
}
