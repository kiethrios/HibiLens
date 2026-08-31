import SwiftUI

struct CaptureMetadataEntrySheet: View {
    private let theme = AppTheme()

    let drafts: [CaptureDraft]
    let onCancel: () -> Void
    let onSave: (CaptureDraft) -> Void

    @State private var selectedDraftID: UUID?

    init(
        drafts: [CaptureDraft],
        onCancel: @escaping () -> Void,
        onSave: @escaping (CaptureDraft) -> Void
    ) {
        self.drafts = drafts
        self.onCancel = onCancel
        self.onSave = onSave
        _selectedDraftID = State(initialValue: drafts.first?.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        confirmationCarousel
                    }
                    .appScreenPadding(top: 28, bottom: 28)
                }
            }
            .navigationTitle(AppL10n.Capture.newCard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppL10n.Common.cancel, action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppL10n.Common.save) {
                        guard let selectedDraft else { return }
                        onSave(selectedDraft)
                    }
                    .disabled(selectedDraft?.metadata.isReadyToSave != true)
                }
            }
        }
    }

    private var selectedDraft: CaptureDraft? {
        guard let selectedDraftID else { return drafts.first }
        return drafts.first { $0.id == selectedDraftID } ?? drafts.first
    }

    private var confirmationCarousel: some View {
        GeometryReader { geometry in
            let cardWidth = min(max(geometry.size.width - 48, 280), 420)
            let sideInset = max((geometry.size.width - cardWidth) / 2, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 18) {
                    ForEach(drafts) { draft in
                        confirmationCard(for: draft)
                            .frame(width: cardWidth)
                            .id(draft.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, sideInset)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedDraftID, anchor: .center)
        }
        .frame(height: 560)
    }

    private func confirmationCard(for draft: CaptureDraft) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            cutoutPanel(for: draft)

            wordingSection(for: draft)
        }
        .padding(24)
        .appCardSurface(
            theme: theme,
            depth: .elevated,
            fill: theme.surfaceInteractiveHighest,
            cornerRadius: 28
        )
    }

    private func wordingSection(for draft: CaptureDraft) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(draft.metadata.japaneseText)
                .font(AppTypography.headlineLarge.weight(.medium))
                .tracking(AppTypography.headlineTracking)
                .appJapaneseLineHeight(fontSize: 24)
                .foregroundStyle(theme.primaryText)

            if let romaji = draft.metadata.optionalTrimmedValue(for: \.romajiText) {
                Text(romaji)
                    .font(AppTypography.labelSmall.weight(.medium))
                    .foregroundStyle(theme.secondaryText)
                    .padding(.top, 4)
            }

            if let kana = draft.metadata.optionalTrimmedValue(for: \.kanaText) {
                Text(kana)
                    .font(AppTypography.bodyMedium.weight(.medium))
                    .appJapaneseLineHeight(fontSize: 14)
                    .foregroundStyle(theme.cardSecondaryText)
                    .padding(.top, 4)
            }

            Text(draft.metadata.translationEnglish.uppercased())
                .font(AppTypography.labelSmall)
                .tracking(AppTypography.labelTracking)
                .foregroundStyle(theme.accentPrimaryStrong)
                .padding(.top, 8)

            if let chinese = draft.metadata.optionalTrimmedValue(for: \.translationChinese) {
                Text(chinese)
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(theme.secondaryText)
                    .padding(.top, 6)
            }
        }
    }

    private func cutoutPanel(for draft: CaptureDraft) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.surfaceSecondarySection)

            Image(uiImage: draft.previewImage)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}
