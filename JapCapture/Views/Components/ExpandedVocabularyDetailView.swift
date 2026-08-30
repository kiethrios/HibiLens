//
//  ExpandedVocabularyDetailView.swift
//  JapCapture
//
//  Created by Codex on 2026/5/8.
//

import SwiftData
import SwiftUI

struct ExpandedObjectDetailLayout {
    private static let cardHorizontalPadding: CGFloat = 16
    private static let maximumImageSideLength: CGFloat = 420
    private static let textSpacing: CGFloat = 28
    private static let textBlockHeight: CGFloat = 176

    let containerSize: CGSize

    var cardFrame: CGRect {
        CGRect(
            x: 0,
            y: 0,
            width: containerSize.width,
            height: containerSize.height
        )
    }

    var imageFrame: CGRect {
        let imageSideLength = min(
            max(cardFrame.width - (Self.cardHorizontalPadding * 2), 0),
            max(cardFrame.height - Self.textSpacing - Self.textBlockHeight - 96, 0),
            Self.maximumImageSideLength
        )
        let contentHeight = imageSideLength + Self.textSpacing + Self.textBlockHeight
        let contentTop = max((cardFrame.height - contentHeight) / 2, 40)

        return CGRect(
            x: cardFrame.midX - (imageSideLength / 2),
            y: cardFrame.minY + contentTop,
            width: imageSideLength,
            height: imageSideLength
        )
    }

    var textTopY: CGFloat {
        imageFrame.maxY + Self.textSpacing
    }

    var textWidth: CGFloat {
        max(cardFrame.width - 64, 0)
    }
}

enum ExpandedObjectDetailStyle {
    static let usesCardSurface = true
    static let usesClearImageStage = true
}

enum ExpandedObjectDetailNavigation {
    static let usesSystemZoomTransition = false
    static let usesSystemBackGesture = false
    static let usesManualFrameOverlayTransition = true
    static let usesHeroImageTransitionLayer = true
    static let scalesLiveDetailViewDuringTransition = false
    static let usesOverlayBackButton = true
    static let usesPagedCardSwipe = true
}

enum VocabularyDetailTransition {
    static let coordinateSpaceName = "vocabularyDetailTransitionRoot"

    static func sourceID(for item: CaptureItem) -> UUID {
        item.id
    }

    static func sourceID(for session: VocabularyDetailSession) -> UUID {
        session.selectedID ?? session.items.first?.id ?? UUID()
    }
}

enum VocabularyDetailTransitionTiming {
    static let initialMeasurementDelay: TimeInterval = 0.04
}

enum VocabularyDetailTransitionFrame {
    static func frame(
        sourceFrame: CGRect,
        containerSize: CGSize,
        isExpanded: Bool
    ) -> CGRect {
        if isExpanded {
            CGRect(origin: .zero, size: containerSize)
        } else {
            sourceFrame
        }
    }
}

enum VocabularyDetailHeroImageTransition {
    static func frame(
        sourceFrame: CGRect,
        targetFrame: CGRect,
        isExpanded: Bool
    ) -> CGRect {
        if isExpanded {
            targetFrame
        } else {
            sourceFrame
        }
    }

    static func targetFrame(measuredFrame: CGRect?, fallbackFrame: CGRect) -> CGRect {
        guard let measuredFrame,
              measuredFrame.width > 0,
              measuredFrame.height > 0 else {
            return fallbackFrame
        }
        return measuredFrame
    }
}

enum VocabularyDetailBackButtonPlacement {
    static func topPadding(safeAreaTop: CGFloat) -> CGFloat {
        max(safeAreaTop + 12, 16)
    }
}

enum VocabularyDetailImageLoadingPolicy {
    static func shouldLoadFullImage(isExpanded: Bool, hasSettled: Bool) -> Bool {
        isExpanded && hasSettled
    }
}

struct VocabularyDetailSourceFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct VocabularyDetailTargetImageFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct VocabularyDetailImagePaths: Equatable {
    let previewPath: String?
    let fullPath: String?

    init(item: CaptureItem) {
        fullPath = item.localImagePath

        if item.thumbnailImagePath != item.localImagePath {
            previewPath = item.thumbnailImagePath
        } else {
            previewPath = nil
        }
    }
}

struct ExpandedVocabularyDetailView: View {
    let session: VocabularyDetailSession
    let onDismiss: (() -> Void)?
    let dismissButtonSafeAreaTop: CGFloat
    let loadsFullResolutionImages: Bool

    private let theme = AppTheme()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var visibleItems: [CaptureItem]
    @State private var selectedID: UUID?
    @State private var removingID: UUID?
    @State private var speechPronouncer = SpeechPronouncer()
    @Query private var cards: [VocabularyCard]

    init(
        session: VocabularyDetailSession,
        onDismiss: (() -> Void)? = nil,
        dismissButtonSafeAreaTop: CGFloat = 0,
        loadsFullResolutionImages: Bool = true
    ) {
        self.session = session
        self.onDismiss = onDismiss
        self.dismissButtonSafeAreaTop = dismissButtonSafeAreaTop
        self.loadsFullResolutionImages = loadsFullResolutionImages
        _visibleItems = State(initialValue: session.items)
        _selectedID = State(initialValue: session.selectedID)
    }

    init(item: CaptureItem) {
        self.init(session: VocabularyDetailSession(selected: item, in: [item])!)
    }

    var body: some View {
        TabView(selection: $selectedID) {
            ForEach(visibleItems) { item in
                GeometryReader { geometry in
                    let layout = ExpandedObjectDetailLayout(containerSize: geometry.size)

                    detailCard(for: item, layout: layout)
                        .frame(width: layout.cardFrame.width, height: layout.cardFrame.height)
                        .removalFlight(
                            isRemoving: removingID == item.id,
                            containerSize: geometry.size
                        )
                }
                .tag(Optional(item.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(theme.background)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            if let onDismiss {
                BackGlassButton(action: onDismiss)
                    .padding(
                        .top,
                        VocabularyDetailBackButtonPlacement.topPadding(
                            safeAreaTop: dismissButtonSafeAreaTop
                        )
                    )
                    .padding(.leading, 16)
            }
        }
    }

    private func detailCard(for item: CaptureItem, layout: ExpandedObjectDetailLayout) -> some View {
        let imagePaths = VocabularyDetailImagePaths(item: item)

        return VStack(spacing: 28) {
            ProgressiveStoredImageView(
                previewRelativePath: imagePaths.previewPath,
                fullRelativePath: loadsFullResolutionImages ? imagePaths.fullPath : nil,
                preservesLoadedAspectRatio: true,
                fallbackAspectRatio: item.imageAspectRatio
            ) {
                Color.clear
            }
            .frame(width: layout.imageFrame.width, height: layout.imageFrame.height)
            .vocabularyDetailTargetImageFrame(id: VocabularyDetailTransition.sourceID(for: item))

            detailText(for: item, width: layout.textWidth)
        }
        .padding(.top, max(layout.imageFrame.minY - layout.cardFrame.minY, 0))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .appCardSurface(
            theme: theme,
            depth: .card,
            fill: theme.surfaceInteractiveHighest,
            cornerRadius: 0
        )
    }

    private func detailText(for item: CaptureItem, width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(item.japanese)
                .font(AppTypography.displayMedium.weight(.medium))
                .appJapaneseLineHeight(fontSize: 36)
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(item.romaji ?? item.english)
                .font(AppTypography.titleSmall.weight(.medium))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)

            if let kana = item.kana {
                Text(kana)
                    .font(AppTypography.bodyMedium.weight(.medium))
                    .appJapaneseLineHeight(fontSize: 14)
                    .foregroundStyle(theme.cardSecondaryText)
                    .multilineTextAlignment(.center)
            }

            Text((item.translation ?? item.english).uppercased())
                .font(AppTypography.labelSmall)
                .tracking(AppTypography.labelTracking)
                .foregroundStyle(theme.accentPrimaryStrong)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            PronunciationButton(action: speakPronunciation)
                .padding(.top, 14)

            if let card = vocabularyCard(for: item) {
                Button(session.source.reviewButtonTitle) {
                    toggleReviewBucket(for: card)
                }
                .buttonStyle(AppSecondaryButtonStyle(theme: theme))
                .padding(.top, 10)
                .disabled(removingID != nil)
            }
        }
        .frame(width: width)
    }

    private func speakPronunciation() {
        guard
            let selectedID,
            let item = visibleItems.first(where: { $0.id == selectedID })
        else { return }

        speechPronouncer.pronounce(
            PronunciationRequest(
                text: PronunciationText.source(
                    preferred: item.kana,
                    fallback: item.japanese
                ),
                languageCode: "ja-JP"
            )
        )
    }

    private func vocabularyCard(for item: CaptureItem) -> VocabularyCard? {
        cards.first { $0.id == item.id }
    }

    private func toggleReviewBucket(for card: VocabularyCard) {
        guard removingID == nil else { return }

        if card.studyProgress == nil {
            let progress = StudyProgress(cardID: card.id)
            modelContext.insert(progress)
            card.studyProgress = progress
        }

        applyReviewAction(to: card)

        if session.source.removesCardAfterReviewAction {
            removeCardFromPager(withID: card.id)
        }
    }

    private func applyReviewAction(to card: VocabularyCard) {
        switch session.source {
        case .todaysCaptures, .learningReview:
            card.studyProgress?.markMastered()
        case .masteredReview:
            card.studyProgress?.markLearned()
        }
    }

    private func removeCardFromPager(withID cardID: UUID) {
        let currentSelection = selectedID ?? cardID
        guard
            let currentItem = visibleItems.first(where: { $0.id == currentSelection }),
            let currentSession = VocabularyDetailSession(selected: currentItem, in: visibleItems)
        else { return }

        let nextSession = currentSession.removingItem(withID: cardID)

        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            removingID = cardID
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            visibleItems = nextSession.items
            selectedID = nextSession.selectedID
            removingID = nil

            if nextSession.items.isEmpty {
                closeDetail()
            }
        }
    }

    private func closeDetail() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

private extension View {
    func removalFlight(isRemoving: Bool, containerSize: CGSize) -> some View {
        offset(
            x: isRemoving ? containerSize.width * 0.72 : 0,
            y: isRemoving ? -containerSize.height * 0.42 : 0
        )
        .rotationEffect(.degrees(isRemoving ? 14 : 0))
        .scaleEffect(isRemoving ? 0.84 : 1)
        .opacity(isRemoving ? 0 : 1)
    }
}

private struct VocabularyDetailTransitionSourceModifier: ViewModifier {
    let id: UUID
    let namespace: Namespace.ID?
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace) { configuration in
                configuration.clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
            }
        } else {
            content
        }
    }
}

extension View {
    func vocabularyDetailSourceFrame(id: UUID) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: VocabularyDetailSourceFramePreferenceKey.self,
                    value: [
                        id: geometry.frame(
                            in: .named(VocabularyDetailTransition.coordinateSpaceName)
                        )
                    ]
                )
            }
        }
    }

    func vocabularyDetailTargetImageFrame(id: UUID) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: VocabularyDetailTargetImageFramePreferenceKey.self,
                    value: [
                        id: geometry.frame(
                            in: .named(VocabularyDetailTransition.coordinateSpaceName)
                        )
                    ]
                )
            }
        }
    }

    func vocabularyDetailTransitionSource(
        id: UUID,
        in namespace: Namespace.ID?,
        cornerRadius: CGFloat
    ) -> some View {
        modifier(
            VocabularyDetailTransitionSourceModifier(
                id: id,
                namespace: namespace,
                cornerRadius: cornerRadius
            )
        )
    }
}

#Preview {
    ExpandedVocabularyDetailView(item: PreviewData.sampleCaptureItems[0])
        .background(AppTheme().background)
}
