import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    private enum Route: Hashable {
        case capture
        case vocabularyDetail(VocabularyDetailSession)
    }

    private let theme = AppTheme()
    @State private var activeDestination: NavDestination = .home
    @State private var homePath: [Route] = []
    @State private var reviewPath: [Route] = []

    var body: some View {
        TabView(selection: $activeDestination) {
            NavigationStack(path: $homePath) {
                HomeView(
                    onCapture: presentCapture,
                    onSeeAll: presentReview,
                    onOpenCard: { item, items in
                        openVocabularyDetail(item, in: items, source: .todaysCaptures)
                    }
                )
                .navigationDestination(for: Route.self, destination: destination)
            }
            .tabItem {
                Label(NavDestination.home.title, systemImage: NavDestination.home.symbol)
            }
            .tag(NavDestination.home)

            NavigationStack(path: $reviewPath) {
                ReviewView(onOpenCard: openVocabularyDetail)
                    .navigationDestination(for: Route.self, destination: destination)
            }
            .tabItem {
                Label(NavDestination.review.title, systemImage: NavDestination.review.symbol)
            }
            .tag(NavDestination.review)

            NavigationStack {
                PersonalView()
            }
            .tabItem {
                Label(NavDestination.personal.title, systemImage: NavDestination.personal.symbol)
            }
            .tag(NavDestination.personal)
        }
        .tint(theme.lensAccent)
        .task { await prewarmImageLabelClassifier() }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .capture:
            CaptureView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        case .vocabularyDetail(let session):
            ExpandedVocabularyDetailView(session: session, prioritizesSystemBack: true)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func presentCapture() {
        guard homePath.last != .capture else { return }
        activeDestination = .home
        homePath.append(.capture)
    }

    private func presentReview() {
        activeDestination = .review
    }

    private func prewarmImageLabelClassifier() async {
        do {
            try await SharedImageLabelClassifier.capture.prewarm()
        } catch {
            print("[SigLIPImageLabelClassifier] app_prewarm=(error) \(error.localizedDescription)")
        }
    }

    private func openVocabularyDetail(
        _ item: CaptureItem,
        in items: [CaptureItem],
        source: VocabularyDetailSource
    ) {
        guard let session = VocabularyDetailSession(selected: item, in: items, source: source) else { return }
        switch source {
        case .todaysCaptures:
            homePath.append(.vocabularyDetail(session))
        case .learningReview, .masteredReview:
            reviewPath.append(.vocabularyDetail(session))
        }
    }
}

struct VocabularyDetailPresentation: Identifiable, Equatable {
    let id: UUID
    let session: VocabularyDetailSession
    let sourceFrame: CGRect
    var isExpanded: Bool
    var hasSettled: Bool

    var selectedItem: CaptureItem? {
        session.items.first { $0.id == session.selectedID } ?? session.items.first
    }

    init(session: VocabularyDetailSession, sourceFrame: CGRect) {
        self.id = VocabularyDetailTransition.sourceID(for: session)
        self.session = session
        self.sourceFrame = sourceFrame
        self.isExpanded = false
        self.hasSettled = false
    }

    mutating func prepareForDismissalHeroReveal() {
        isExpanded = true
        hasSettled = false
    }

    mutating func collapseDismissalHero() {
        isExpanded = false
        hasSettled = false
    }
}

private struct PlaceholderScreen: View {
    private let theme = AppTheme()
    let title: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                Text(title)
                    .font(AppTypography.displaySmall)
                    .tracking(AppTypography.displayTracking)
                    .foregroundStyle(theme.primaryText)

                Text(AppL10n.Placeholder.screenInProgress)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(theme.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .appScreenPadding()
        }
        .background(theme.background)
    }
}


#Preview {
    ContentView()
        .modelContainer(PreviewModelContainer.shared)
}
