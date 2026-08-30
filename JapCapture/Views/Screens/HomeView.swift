//
//  HomeView.swift
//  JapCapture
//
//  Created by kiethrios on 2026/4/10.
//

import SwiftUI
import SwiftData

enum HomeVisualRefillSpec {
    static var discoveryTitle: String { AppL10n.Home.todaysDiscovery }
    static var primaryCaptureActionTitle: String { AppL10n.Home.captureNow }
    static var keepsakesSectionTitle: String { AppL10n.Home.keepsakes }
    static var seeAllActionTitle: String { AppL10n.Home.seeAll }
    static var statsSectionTitle: String { AppL10n.Home.progress }
    static var todayStatisticTitle: String { AppL10n.Home.today }
    static var thisMonthStatisticTitle: String { AppL10n.Home.thisMonth }
    static var wordsCapturedStatisticSubtitle: String { AppL10n.Home.wordsCaptured }

    static let dailyDiscoveryHeroHeight: CGFloat = 224
    static let lensButtonDiameter: CGFloat = 124
    static let emptyKeepsakeTextMaxWidth: CGFloat = 112
    static let statCardMinHeight: CGFloat = 104
}

enum HomeCaptureCardTapAction: Equatable {
    case openCard
    case createCapture

    static func forItem(_ item: CaptureItem) -> HomeCaptureCardTapAction {
        item.isPlaceholder ? .createCapture : .openCard
    }
}

enum HomeCaptureItems {
    static func todaysItems(
        from cards: [VocabularyCard],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [CaptureItem] {
        let todaysCards = cards
            .filter { calendar.isDate($0.capturedAt, inSameDayAs: now) }
            .filter { $0.matchesReviewBucket(.learned) }
            .sorted { $0.capturedAt > $1.capturedAt }
            .map { $0.captureItem() }

        return todaysCards + [CaptureItem(placeholder: ())]
    }
}

struct HomeView: View {
    private let theme = AppTheme()
    let onCapture: () -> Void
    let onSeeAll: () -> Void
    let onOpenCard: (CaptureItem, [CaptureItem]) -> Void
    let transitionNamespace: Namespace.ID?

    @Query(sort: \VocabularyCard.capturedAt, order: .reverse) private var cards: [VocabularyCard]

    init(
        onCapture: @escaping () -> Void,
        onSeeAll: @escaping () -> Void,
        onOpenCard: @escaping (CaptureItem, [CaptureItem]) -> Void = { _, _ in },
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.onCapture = onCapture
        self.onSeeAll = onSeeAll
        self.onOpenCard = onOpenCard
        self.transitionNamespace = transitionNamespace
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                captureSection
                keepsakesSection
                statisticSection
            }
            .appScreenPadding()
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private var captureSection: some View {
        DailyDiscoveryHero(
            featuredItem: todaysFeaturedItem,
            onCapture: onCapture,
            onOpenCard: todaysFeaturedItem.map { item in
                { onOpenCard(item, recentKeepsakeItems) }
            }
        )
    }

    private var keepsakesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            AppEditorialHeader(
                theme: theme,
                title: HomeVisualRefillSpec.keepsakesSectionTitle,
                actionTitle: HomeVisualRefillSpec.seeAllActionTitle,
                action: onSeeAll
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.compactCardGap) {
                    if savedKeepsakeItems.isEmpty {
                        ForEach(SampleKeepsakeCard.sampleCards) { sample in
                            SampleKeepsakeCard(card: sample)
                        }
                    }

                    ForEach(recentKeepsakeItems) { item in
                        CaptureCard(
                            item: item,
                            onTap: tapHandler(for: item),
                            transitionNamespace: item.isPlaceholder ? nil : transitionNamespace
                        )
                    }
                }
                .padding(.horizontal, AppLayout.editorialSectionInnerGutter)
            }
        }
    }

    private var statisticSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppEditorialHeader(theme: theme, title: HomeVisualRefillSpec.statsSectionTitle)

            HStack(spacing: AppLayout.compactCardGap) {
                ForEach(statisticMetrics) { metric in
                    StatisticMetricCard(metric: metric)
                }
            }
            .padding(.horizontal, AppLayout.editorialSectionInnerGutter)
        }
    }

    private var recentCaptureItems: [CaptureItem] {
        HomeCaptureItems.todaysItems(from: cards)
    }

    private var todaysFeaturedItem: CaptureItem? {
        recentCaptureItems.first { !$0.isPlaceholder }
    }

    private var savedKeepsakeItems: [CaptureItem] {
        cards
            .filter { $0.matchesReviewBucket(.learned) }
            .sorted { $0.capturedAt > $1.capturedAt }
            .prefix(8)
            .map { $0.captureItem() }
    }

    private var recentKeepsakeItems: [CaptureItem] {
        savedKeepsakeItems + [CaptureItem(placeholder: ())]
    }

    private func tapHandler(for item: CaptureItem) -> (() -> Void)? {
        switch HomeCaptureCardTapAction.forItem(item) {
        case .openCard:
            { onOpenCard(item, recentKeepsakeItems) }
        case .createCapture:
            onCapture
        }
    }

    private var statisticMetrics: [StatisticMetric] {
        let calendar = Calendar.autoupdatingCurrent
        let monthWordCount = cards.filter { calendar.isDate($0.capturedAt, equalTo: .now, toGranularity: .month) }.count
        let todayCaptureCount = cards.filter { calendar.isDate($0.capturedAt, inSameDayAs: .now) }.count

        return [
            StatisticMetric(
                value: "\(todayCaptureCount)",
                title: HomeVisualRefillSpec.todayStatisticTitle,
                subtitle: HomeVisualRefillSpec.wordsCapturedStatisticSubtitle,
                symbol: "calendar.badge.clock"
            ),
            StatisticMetric(
                value: "\(monthWordCount)",
                title: HomeVisualRefillSpec.thisMonthStatisticTitle,
                subtitle: HomeVisualRefillSpec.wordsCapturedStatisticSubtitle,
                symbol: "sparkles"
            )
        ]
    }
}

private struct DailyDiscoveryHero: View {
    private let theme = AppTheme()

    let featuredItem: CaptureItem?
    let onCapture: () -> Void
    let onOpenCard: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            heroSceneBackground

            VStack(alignment: .leading, spacing: 13) {
                Text(HomeVisualRefillSpec.discoveryTitle)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(theme.primaryText)

                Text(AppL10n.Home.discoverySubtitle)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(theme.secondaryText)
                    .lineSpacing(3)

            }
            .padding(.top, 30)
            .padding(.leading, 28)
            .frame(maxWidth: 220, alignment: .leading)
            .zIndex(2)

            discoveryStage
                .frame(width: 150, height: 186)
                .rotationEffect(.degrees(featuredItem == nil ? 6 : 3))
                .shadow(color: theme.primaryText.opacity(0.12), radius: 14, x: 0, y: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 24)
                .padding(.top, 46)
                .zIndex(1)

            LensCaptureButton(action: onCapture)
                .frame(width: HomeVisualRefillSpec.lensButtonDiameter)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 34)
                .padding(.bottom, 24)
                .zIndex(1)
        }
        .frame(maxWidth: .infinity, minHeight: HomeVisualRefillSpec.dailyDiscoveryHeroHeight + 56)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius, style: .continuous)
                .stroke(theme.discoveryAccent.opacity(0.14), lineWidth: 1)
        }
        .appAmbientDepth(theme: theme, depth: .elevated, yOffset: 10)
    }

    private var heroSceneBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.keepsakeCardRaised,
                    theme.discoveryMuted.opacity(0.42),
                    theme.galleryBand.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(theme.lensMuted.opacity(0.28))
                .frame(width: 210, height: 210)
                .blur(radius: 36)
                .offset(x: 126, y: -54)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.keepsakeCard.opacity(0.42))
                .frame(width: 236, height: 42)
                .rotationEffect(.degrees(-3))
                .offset(x: 106, y: 118)
        }
    }

    @ViewBuilder
    private var discoveryStage: some View {
        if let featuredItem {
            Button {
                onOpenCard?()
            } label: {
                FeaturedKeepsakeSlot(item: featuredItem)
            }
            .buttonStyle(.plain)
        } else {
            EmptyKeepsakeSlot()
        }
    }
}

private struct FeaturedKeepsakeSlot: View {
    private let theme = AppTheme()
    let item: CaptureItem

    var body: some View {
        let content = CaptureCardDisplayContent.from(item)

        VStack(spacing: 10) {
            ZStack {
                StoredImageView(relativePath: item.thumbnailImagePath) {
                    theme.subjectStage
                }
                .padding(10)
            }
            .frame(height: 100)
            .appSubjectStageSurface(theme: theme)

            VStack(alignment: .leading, spacing: 5) {
                Text(content.japanese)
                    .font(AppTypography.headlineMedium.weight(.medium))
                    .appJapaneseLineHeight(fontSize: 20)
                    .foregroundStyle(theme.textJapanese)
                    .lineLimit(1)

                Text(content.reading)
                    .font(AppTypography.bodySmall.weight(.medium))
                    .foregroundStyle(theme.cardSecondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .appKeepsakeCardSurface(theme: theme, cornerRadius: AppLayout.compactKeepsakeCardCornerRadius)
    }
}

private struct EmptyKeepsakeSlot: View {
    private let theme = AppTheme()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius - 4, style: .continuous)
                .stroke(theme.discoveryAccent.opacity(0.46), lineWidth: 1.2)
                .padding(16)

            VStack(spacing: 12) {
                Image(systemName: "camera")
                    .font(AppTypography.displaySmall.weight(.regular))
                    .foregroundStyle(theme.cardSecondaryText.opacity(0.86))

                Text(AppL10n.Home.emptyKeepsake)
                    .font(AppTypography.bodySmall.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: HomeVisualRefillSpec.emptyKeepsakeTextMaxWidth)
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [theme.keepsakeCardRaised, theme.keepsakeCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius, style: .continuous)
                .stroke(theme.primaryText.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct LensCaptureButton: View {
    private let theme = AppTheme()
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            photographicLens
                .frame(
                    width: HomeVisualRefillSpec.lensButtonDiameter - 8,
                    height: HomeVisualRefillSpec.lensButtonDiameter - 8
                )
                .frame(
                    width: HomeVisualRefillSpec.lensButtonDiameter,
                    height: HomeVisualRefillSpec.lensButtonDiameter
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(HomeVisualRefillSpec.primaryCaptureActionTitle)
    }

    private var photographicLens: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.lensAccent.opacity(0.96),
                            theme.accentPrimaryMuted,
                            theme.primaryText
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 92
                    )
                )

            Circle()
                .strokeBorder(theme.primaryText.opacity(0.45), lineWidth: 2)

            Circle()
                .strokeBorder(theme.keepsakeCardRaised.opacity(0.55), lineWidth: 1)
                .padding(5)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.keepsakeCardRaised.opacity(0.34),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .padding(10)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            theme.keepsakeCardRaised.opacity(0.78),
                            theme.primaryText.opacity(0.7),
                            theme.keepsakeCardRaised.opacity(0.44),
                            theme.primaryText.opacity(0.86),
                            theme.keepsakeCardRaised.opacity(0.78)
                        ],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 54, height: 54)

            Circle()
                .fill(theme.primaryText.opacity(0.88))
                .frame(width: 47, height: 47)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.lensMuted.opacity(0.74),
                            theme.primaryText.opacity(0.94),
                            Color.black.opacity(0.96)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 36
                    )
                )
                .frame(width: 42, height: 42)

            Circle()
                .stroke(theme.keepsakeCardRaised.opacity(0.18), lineWidth: 1)
                .frame(width: 31, height: 31)

            Circle()
                .fill(theme.keepsakeCardRaised.opacity(0.54))
                .frame(width: 8, height: 8)
                .blur(radius: 2)
                .offset(x: -9, y: -11)

            Circle()
                .fill(theme.keepsakeCardRaised.opacity(0.82))
                .frame(width: 5, height: 5)
                .offset(x: -29, y: -29)
        }
        .shadow(color: theme.primaryText.opacity(0.24), radius: 9, x: 0, y: 6)
        .shadow(color: theme.keepsakeCardRaised.opacity(0.7), radius: 1, x: -1, y: -1)
    }
}

private struct SampleKeepsakeCard: View {
    struct Model: Identifiable {
        let id = UUID()
        let symbol: String
        let japanese: String
        let reading: String
        let romaji: String
        let translation: String
        let tint: Color
    }

    static let sampleCards = [
        Model(
            symbol: "cup.and.saucer.fill",
            japanese: "コップ",
            reading: "こっぷ",
            romaji: "koppu",
            translation: "CUP",
            tint: AppColorToken.discoveryMuted.color
        ),
        Model(
            symbol: "book.closed.fill",
            japanese: "本",
            reading: "ほん",
            romaji: "hon",
            translation: "BOOK",
            tint: AppColorToken.lensMuted.color
        )
    ]

    private let theme = AppTheme()
    let card: Model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: AppLayout.imageFrameCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.keepsakeCardRaised, card.tint.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: card.symbol)
                    .font(AppTypography.displayMedium.weight(.regular))
                    .foregroundStyle(theme.lensAccent.opacity(0.9))
                    .shadow(color: theme.primaryText.opacity(0.12), radius: 8, x: 0, y: 6)
            }
            .frame(height: 126)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppLayout.compactKeepsakeCardCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: AppLayout.compactKeepsakeCardCornerRadius,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.japanese)
                        .font(AppTypography.japaneseCardTitle)
                        .appJapaneseLineHeight(fontSize: 28)
                        .foregroundStyle(theme.textJapanese)

                    Spacer(minLength: 0)

                    Image(systemName: "ellipsis")
                        .font(AppTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(theme.cardSecondaryText)
                }

                Text(card.reading)
                    .font(AppTypography.japaneseSupport)
                    .foregroundStyle(theme.cardSecondaryText)

                Text(card.romaji)
                    .font(AppTypography.romajiHelper)
                    .foregroundStyle(theme.secondaryText)

                Text(card.translation)
                    .font(AppTypography.translationMetadata)
                    .tracking(AppTypography.labelTracking)
                    .foregroundStyle(theme.primaryText.opacity(0.78))
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(
            width: 150,
            height: 252
        )
        .appCardSurface(
            theme: theme,
            depth: .card,
            fill: theme.keepsakeCard,
            cornerRadius: AppLayout.compactKeepsakeCardCornerRadius
        )
        .opacity(0.94)
    }
}

private struct StatisticMetricCard: View {
    private let theme = AppTheme()
    let metric: StatisticMetric

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(metric.symbol == "calendar.badge.clock" ? theme.accentSupportStrong : theme.accentSupportMuted)
                    .frame(width: 40, height: 40)

                Image(systemName: metric.symbol)
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .font(AppTypography.bodyMedium.weight(.medium))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)

                Text(metric.value)
                    .font(AppTypography.displayMedium.weight(.medium))
                    .foregroundStyle(theme.primaryText)

                if let subtitle = metric.subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(theme.cardSecondaryText)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: HomeVisualRefillSpec.statCardMinHeight, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .appCardSurface(
            theme: theme,
            depth: .card,
            fill: theme.keepsakeCard,
            cornerRadius: AppLayout.compactKeepsakeCardCornerRadius
        )
    }
}

#Preview {
    HomeView(onCapture: { }, onSeeAll: { })
        .background(AppTheme().background)
        .modelContainer(PreviewModelContainer.shared)
}
