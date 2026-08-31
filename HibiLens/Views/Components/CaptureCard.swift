import SwiftUI

struct CaptureCard: View {
    private let theme = AppTheme()

    let item: CaptureItem
    let onTap: (() -> Void)?
    let transitionNamespace: Namespace.ID?

    init(
        item: CaptureItem,
        onTap: (() -> Void)?,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.item = item
        self.onTap = onTap
        self.transitionNamespace = transitionNamespace
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    cardBody
                }
                .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        if item.isPlaceholder {
            placeholderCard
        } else {
            contentCard
        }
    }

    private var contentCard: some View {
        let content = CaptureCardDisplayContent.from(item)

        return VStack(alignment: .leading, spacing: 0) {
            ZStack {
                StoredImageView(relativePath: item.thumbnailImagePath) {
                    theme.subjectStage
                }
                .padding(12)
            }
            .vocabularyDetailSourceFrame(id: VocabularyDetailTransition.sourceID(for: item))
            .frame(height: AppLayout.compactCaptureCardImageHeight - 18)
            .appSubjectStageSurface(theme: theme)
            .padding(10)
            .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: AppLayout.compactCaptureCardTextSpacing) {
                Text(content.japanese)
                    .font(AppTypography.japaneseCardTitle)
                    .appJapaneseLineHeight(fontSize: 28)
                    .foregroundStyle(theme.textJapanese)
                    .lineLimit(1)

                Text(content.reading)
                    .font(AppTypography.japaneseSupport)
                    .appJapaneseLineHeight(fontSize: 17)
                    .foregroundStyle(theme.cardSecondaryText)
                    .lineLimit(1)

                Text(content.romaji)
                    .font(AppTypography.romajiHelper)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)

                Text(content.translation.uppercased())
                    .font(AppTypography.translationMetadata)
                    .tracking(AppTypography.labelTracking)
                    .foregroundStyle(theme.lensAccent)
                    .lineLimit(1)
            }
            .padding(.horizontal, AppLayout.compactCaptureCardTextPadding)
            .padding(.top, 4)
            .padding(.bottom, AppLayout.compactCaptureCardTextPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(
            width: AppLayout.compactCaptureCardWidth,
            height: AppLayout.compactCaptureCardHeight
        )
        .appCardSurface(
            theme: theme,
            depth: .card,
            fill: theme.keepsakeCard,
            cornerRadius: AppLayout.compactKeepsakeCardCornerRadius
        )
        .vocabularyDetailTransitionSource(
            id: VocabularyDetailTransition.sourceID(for: item),
            in: transitionNamespace,
            cornerRadius: AppLayout.compactKeepsakeCardCornerRadius
        )
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.lensMuted.opacity(0.72))
                    .frame(width: AppLayout.compactCaptureIconDiameter, height: AppLayout.compactCaptureIconDiameter)

                Image(systemName: "plus")
                    .font(AppTypography.headlineMedium.weight(.medium))
                    .foregroundStyle(theme.lensAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(AppL10n.Home.newKeepsake)
                    .font(AppTypography.titleMedium.weight(.semibold))
                    .foregroundStyle(theme.primaryText)

                Text(AppL10n.Home.captureNow)
                    .font(AppTypography.translationMetadata)
                    .tracking(AppTypography.labelTracking)
                    .foregroundStyle(theme.lensAccent)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(
            width: AppLayout.compactCaptureCardWidth,
            height: AppLayout.compactCaptureCardHeight,
            alignment: .topLeading
        )
        .background(
            theme.galleryBand.opacity(0.84),
            in: RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius, style: .continuous)
                .stroke(theme.lensAccent.opacity(0.14), lineWidth: 1)
        }
    }
}

#Preview {
    HStack {
        CaptureCard(item: PreviewData.sampleCaptureItems[0], onTap: { })
        CaptureCard(item: PreviewData.sampleCaptureItems[2], onTap: { })
    }
    .padding()
    .background(AppTheme().background)
}
