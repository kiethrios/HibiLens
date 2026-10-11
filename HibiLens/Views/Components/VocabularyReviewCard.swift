import SwiftUI

struct VocabularyReviewCard: View {
    private enum CardLayout {
        static let imageMinHeight = ReviewVisualRefillSpec.imageMinHeight
        static let imageMaxHeight = ReviewVisualRefillSpec.imageMaxHeight
        static let cardCornerRadius = ReviewVisualRefillSpec.cardCornerRadius
        static let imagePadding: CGFloat = 10
        static let textHorizontalPadding: CGFloat = 16
        static let textBottomPadding: CGFloat = 18
    }

    private let theme = AppTheme()

    let item: CaptureItem
    let onTap: () -> Void
    let isDeleteModeActive: Bool
    let onLongPress: () -> Void
    let onDelete: () -> Void
    let transitionNamespace: Namespace.ID?

    @State private var isShaking = false
    private var jiggle: ReviewCardJiggleParameters {
        ReviewCardJiggleParameters.forCard(id: item.id)
    }

    init(
        item: CaptureItem,
        onTap: @escaping () -> Void,
        isDeleteModeActive: Bool = false,
        onLongPress: @escaping () -> Void = { },
        onDelete: @escaping () -> Void = { },
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.item = item
        self.onTap = onTap
        self.isDeleteModeActive = isDeleteModeActive
        self.onLongPress = onLongPress
        self.onDelete = onDelete
        self.transitionNamespace = transitionNamespace
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button {
                guard !isDeleteModeActive else { return }
                onTap()
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
            .disabled(isDeleteModeActive)

            if isDeleteModeActive {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(theme.destructiveMuted, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(theme.keepsakeCard.opacity(0.88), lineWidth: 2)
                        }
                        .appAmbientDepth(theme: theme, depth: .elevated, yOffset: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppL10n.Review.deleteCardAccessibilityLabel(item.japanese))
                .offset(x: -6, y: -6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .rotationEffect(isDeleteModeActive ? .degrees(isShaking ? jiggle.angleDegrees : -jiggle.angleDegrees) : .degrees(0))
        .animation(
            isDeleteModeActive
            ? .easeInOut(duration: jiggle.duration).repeatForever(autoreverses: true)
            : .easeInOut(duration: 0.12),
            value: isShaking
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    onLongPress()
                }
        )
        .onAppear {
            updateShakingState(isActive: isDeleteModeActive)
        }
        .onChange(of: isDeleteModeActive) { _, isActive in
            updateShakingState(isActive: isActive)
        }
    }

    private func updateShakingState(isActive: Bool) {
        guard isActive else {
            isShaking = false
            return
        }

        isShaking = false

        DispatchQueue.main.asyncAfter(deadline: .now() + jiggle.delay) {
            guard isDeleteModeActive else { return }
            isShaking = true
        }
    }

    private var cardContent: some View {
        let content = CaptureCardDisplayContent.from(item)

        return VStack(alignment: .leading, spacing: 0) {
            subjectStage

            VStack(alignment: .leading, spacing: AppLayout.compactCaptureCardTextSpacing) {
                Text(content.japanese)
                    .font(AppTypography.japaneseCardTitle)
                    .appJapaneseLineHeight(fontSize: 28)
                    .foregroundStyle(theme.textJapanese)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(content.reading)
                    .font(AppTypography.japaneseSupport)
                    .appJapaneseLineHeight(fontSize: 17)
                    .foregroundStyle(theme.cardSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Text(content.romaji)
                    .font(AppTypography.romajiHelper)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Text(content.translation.uppercased())
                    .font(AppTypography.translationMetadata)
                    .tracking(AppTypography.labelTracking)
                    .foregroundStyle(theme.lensAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, CardLayout.textHorizontalPadding)
            .padding(.top, 4)
            .padding(.bottom, CardLayout.textBottomPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .appKeepsakeCardSurface(theme: theme, cornerRadius: CardLayout.cardCornerRadius)
        .vocabularyDetailTransitionSource(
            id: VocabularyDetailTransition.sourceID(for: item),
            in: transitionNamespace,
            cornerRadius: CardLayout.cardCornerRadius
        )
    }

    private var subjectStage: some View {
        ZStack {
            StoredImageView(
                relativePath: item.thumbnailImagePath,
                preservesLoadedAspectRatio: true,
                fallbackAspectRatio: item.imageAspectRatio
            ) {
                theme.subjectStage
            }
            .padding(CardLayout.imagePadding)
        }
        .vocabularyDetailSourceFrame(id: VocabularyDetailTransition.sourceID(for: item))
        .frame(maxWidth: .infinity)
        .frame(
            minHeight: CardLayout.imageMinHeight,
            maxHeight: CardLayout.imageMaxHeight
        )
        .appSubjectStageSurface(theme: theme)
        .padding(10)
        .padding(.bottom, 2)
    }
}

#Preview {
    VocabularyReviewCard(item: PreviewData.sampleCaptureItems[0], onTap: { })
        .padding()
        .background(AppTheme().background)
}
