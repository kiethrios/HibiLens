//
//  ContentView.swift
//  JapCapture
//
//  Created by kiethrios on 2026/3/31.
//

import SwiftData
import SwiftUI
import UIKit

enum RootNavigationTransitionDirection: Equatable {
    case forward
    case backward

    init?(from source: NavDestination, to destination: NavDestination) {
        guard source != destination,
              let sourceIndex = Self.index(of: source),
              let destinationIndex = Self.index(of: destination) else {
            return nil
        }

        self = destinationIndex > sourceIndex ? .forward : .backward
    }

    private static func index(of destination: NavDestination) -> Int? {
        switch destination {
        case .home: 0
        case .review: 1
        case .personal: 2
        case .capture: nil
        }
    }
}

struct ContentView: View {
    private enum Route: Hashable {
        case capture
    }

    private let vocabularyDetailAnimationDuration: TimeInterval = 0.42
    private let vocabularyDetailAnimation = Animation.spring(response: 0.42, dampingFraction: 0.88)
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var activeDestination: NavDestination = .home
    @State private var rootNavigationDirection: RootNavigationTransitionDirection = .forward
    @State private var path: [Route] = []
    @State private var vocabularyDetailSourceFrames: [UUID: CGRect] = [:]
    @State private var activeVocabularyDetailPresentation: VocabularyDetailPresentation?

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                BottomNavScreen(activeDestination: $activeDestination) { destination in
                    if destination == .capture {
                        presentCapture()
                    } else {
                        selectRootDestination(destination)
                    }
                } content: {
                    rootContent
                        .id(activeDestination.id)
                        .transition(rootContentTransition)
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .capture:
                        CaptureView()
                    }
                }
            }

            if let activeVocabularyDetailPresentation {
                VocabularyDetailTransitionOverlay(
                    presentation: activeVocabularyDetailPresentation,
                    onDismiss: closeVocabularyDetail
                )
                .zIndex(10)
            }
        }
        .coordinateSpace(name: VocabularyDetailTransition.coordinateSpaceName)
        .onPreferenceChange(VocabularyDetailSourceFramePreferenceKey.self) { sourceFrames in
            vocabularyDetailSourceFrames = sourceFrames
        }
        .task {
            await prewarmImageLabelClassifier()
        }
    }

    private var rootContentTransition: AnyTransition {
        if accessibilityReduceMotion {
            return .opacity
        }

        switch rootNavigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch activeDestination {
        case .home:
            HomeView(
                onCapture: presentCapture,
                onSeeAll: presentReview,
                onOpenCard: { item, items in
                    openVocabularyDetail(item, in: items, source: .todaysCaptures)
                }
            )
        case .review:
            ReviewView(
                onOpenCard: openVocabularyDetail
            )
        case .personal:
            PersonalView()
        case .capture:
            HomeView(
                onCapture: presentCapture,
                onSeeAll: presentReview,
                onOpenCard: { item, items in
                    openVocabularyDetail(item, in: items, source: .todaysCaptures)
                }
            )
        }
    }

    private func presentCapture() {
        guard path.last != .capture else { return }
        print("[ContentView] presentCapture")
        path.append(.capture)
    }

    private func selectRootDestination(_ destination: NavDestination) {
        guard let direction = RootNavigationTransitionDirection(
            from: activeDestination,
            to: destination
        ) else { return }

        rootNavigationDirection = direction
        withAnimation(AppMotion.rootNavigationAnimation) {
            activeDestination = destination
        }
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
        guard let session = VocabularyDetailSession(
            selected: item,
            in: items,
            source: source
        ) else { return }
        let sourceID = VocabularyDetailTransition.sourceID(for: item)
        let sourceFrame = vocabularyDetailSourceFrames[sourceID] ?? .zero
        let presentation = VocabularyDetailPresentation(session: session, sourceFrame: sourceFrame)
        activeVocabularyDetailPresentation = presentation

        DispatchQueue.main.asyncAfter(deadline: .now() + VocabularyDetailTransitionTiming.initialMeasurementDelay) {
            withAnimation(vocabularyDetailAnimation) {
                expandVocabularyDetailPresentation(id: presentation.id)
            }
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + VocabularyDetailTransitionTiming.initialMeasurementDelay + vocabularyDetailAnimationDuration
        ) {
            settleVocabularyDetailPresentation(id: presentation.id)
        }
    }

    private func expandVocabularyDetailPresentation(id: UUID) {
        guard var presentation = activeVocabularyDetailPresentation,
              presentation.id == id else { return }
        presentation.isExpanded = true
        activeVocabularyDetailPresentation = presentation
    }

    private func settleVocabularyDetailPresentation(id: UUID) {
        guard var presentation = activeVocabularyDetailPresentation,
              presentation.id == id,
              presentation.isExpanded else { return }
        presentation.hasSettled = true
        activeVocabularyDetailPresentation = presentation
    }

    private func closeVocabularyDetail() {
        guard let closingID = activeVocabularyDetailPresentation?.id else { return }

        guard var presentation = activeVocabularyDetailPresentation else { return }
        presentation.prepareForDismissalHeroReveal()
        activeVocabularyDetailPresentation = presentation

        DispatchQueue.main.async {
            withAnimation(vocabularyDetailAnimation) {
                guard var presentation = activeVocabularyDetailPresentation,
                      presentation.id == closingID else { return }
                presentation.collapseDismissalHero()
                activeVocabularyDetailPresentation = presentation
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            if activeVocabularyDetailPresentation?.id == closingID,
               activeVocabularyDetailPresentation?.isExpanded == false {
                activeVocabularyDetailPresentation = nil
            }
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

private enum VocabularyDetailSafeArea {
    @MainActor
    static var topInset: CGFloat {
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let keyWindow = activeScene?.windows.first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.top ?? 0
    }
}

private struct VocabularyDetailTransitionOverlay: View {
    let presentation: VocabularyDetailPresentation
    let onDismiss: () -> Void
    private let theme = AppTheme()
    @State private var targetImageFrames: [UUID: CGRect] = [:]

    var body: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let fallbackImageFrame = ExpandedObjectDetailLayout(containerSize: containerSize).imageFrame
            let targetImageFrame = VocabularyDetailHeroImageTransition.targetFrame(
                measuredFrame: targetImageFrames[presentation.id],
                fallbackFrame: fallbackImageFrame
            )
            let heroFrame = VocabularyDetailHeroImageTransition.frame(
                sourceFrame: usableSourceFrame(fallback: targetImageFrame),
                targetFrame: targetImageFrame,
                isExpanded: presentation.isExpanded
            )
            let shouldLoadFullImage = VocabularyDetailImageLoadingPolicy.shouldLoadFullImage(
                isExpanded: presentation.isExpanded,
                hasSettled: presentation.hasSettled
            )

            ZStack(alignment: .topLeading) {
                theme.background
                    .ignoresSafeArea()

                ExpandedVocabularyDetailView(
                    session: presentation.session,
                    loadsFullResolutionImages: shouldLoadFullImage
                )
                .frame(width: containerSize.width, height: containerSize.height)
                .opacity(presentation.hasSettled ? 1 : 0)
                .allowsHitTesting(presentation.hasSettled)

                if !presentation.hasSettled, let selectedItem = presentation.selectedItem {
                    VocabularyDetailHeroImageView(item: selectedItem, frame: heroFrame)
                        .allowsHitTesting(false)
                }

                if presentation.hasSettled {
                    BackGlassButton(action: onDismiss)
                        .padding(
                            .top,
                            VocabularyDetailBackButtonPlacement.topPadding(
                                safeAreaTop: VocabularyDetailSafeArea.topInset
                            )
                        )
                        .padding(.leading, 16)
                        .contentShape(Rectangle())
                        .zIndex(20)
                }
            }
            .onPreferenceChange(VocabularyDetailTargetImageFramePreferenceKey.self) { frames in
                targetImageFrames = frames
            }
        }
        .ignoresSafeArea()
    }

    private func usableSourceFrame(fallback: CGRect) -> CGRect {
        guard presentation.sourceFrame.width > 0,
              presentation.sourceFrame.height > 0 else {
            return fallback
        }
        return presentation.sourceFrame
    }
}

private struct VocabularyDetailHeroImageView: View {
    let item: CaptureItem
    let frame: CGRect

    var body: some View {
        StoredImageView(
            relativePath: item.thumbnailImagePath,
            preservesLoadedAspectRatio: true,
            fallbackAspectRatio: item.imageAspectRatio
        ) {
            Color.clear
        }
        .frame(width: frame.width, height: frame.height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .position(x: frame.midX, y: frame.midY)
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
