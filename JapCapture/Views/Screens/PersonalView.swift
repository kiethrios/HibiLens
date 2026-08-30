//
//  PersonalView.swift
//  JapCapture
//
//  Created by Codex on 2026/4/15.
//

import SwiftUI
import SwiftData

enum PersonalVisualRefillSpec {
    static var title: String { AppL10n.Personal.galleryTitle }
    static var discoveriesLabel: String { AppL10n.Personal.discoveries }
    static var discoveryUnitLabel: String { AppL10n.Personal.wordsCaptured }
    static var thisMonthLabel: String { AppL10n.Personal.thisMonth }
    static var masteredLabel: String { AppL10n.Personal.mastered }
    static var informationLabel: String { AppL10n.Personal.information }
    static var supportLabel: String { AppL10n.Personal.support }
    static var privacyPolicyLabel: String { AppL10n.Personal.privacyPolicy }
    static var termsLabel: String { AppL10n.Personal.terms }
    static var sourcesAndLicensesLabel: String { AppL10n.Personal.sourcesAndLicenses }
}

enum PersonalAppearanceSpec {
    static var title: String { AppL10n.Personal.appearance }

    static func title(for preference: AppAppearancePreference) -> String {
        switch preference {
        case .system: AppL10n.Personal.appearanceSystem
        case .day: AppL10n.Personal.appearanceDay
        case .dark: AppL10n.Personal.appearanceDark
        }
    }
}

enum PersonalExternalSupportLinks {
    private static let pagesBaseURL = "https://kiethrios.github.io/PrivacyPolicy/"

    static func supportURL(for locale: Locale) -> URL? {
        URL(string: pagesBaseURL + localizedFileName(
            english: "HibiLensSupport_en.html",
            simplifiedChinese: "HibiLensSupport_zh-Hans.html",
            locale: locale
        ))
    }

    static func privacyPolicyURL(for locale: Locale) -> URL? {
        URL(string: pagesBaseURL + localizedFileName(
            english: "HibiLensPrivacyPolicy_en.html",
            simplifiedChinese: "HibiLensPrivacyPolicy_zh-Hans.html",
            locale: locale
        ))
    }

    static func termsURL(for locale: Locale) -> URL? {
        URL(string: pagesBaseURL + localizedFileName(
            english: "HibiLensTerms_en.html",
            simplifiedChinese: "HibiLensTerms_zh-Hans.html",
            locale: locale
        ))
    }

    private static func localizedFileName(
        english: String,
        simplifiedChinese: String,
        locale: Locale
    ) -> String {
        locale.identifier.lowercased().hasPrefix("zh") ? simplifiedChinese : english
    }
}

struct PersonalGalleryMetrics: Equatable {
    let totalDiscoveries: Int
    let thisMonth: Int
    let mastered: Int

    static func from(
        cards: [VocabularyCard],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> PersonalGalleryMetrics {
        PersonalGalleryMetrics(
            totalDiscoveries: cards.count,
            thisMonth: cards.filter {
                calendar.isDate($0.capturedAt, equalTo: now, toGranularity: .month)
            }.count,
            mastered: cards.filter {
                $0.matchesReviewBucket(.mastered)
            }.count
        )
    }
}

private enum PersonalLayout {
    static let sectionSpacing: CGFloat = 40
    static let compactCardHeight: CGFloat = 151
    static let rowSpacing: CGFloat = 0
}

struct PersonalView: View {

    @Environment(\.locale) private var locale
    private let theme = AppTheme()
    @State private var presentedLicenseNotice: PersonalLicenseNotice?
    @AppStorage(AppAppearancePreference.storageKey)
    private var appearanceRawValue = AppAppearancePreference.defaultValue.rawValue
    @Query(sort: \VocabularyCard.capturedAt, order: .reverse) private var cards: [VocabularyCard]

    private var supportRows: [PersonalSupportRowData] {
        [
            .init(
                title: PersonalVisualRefillSpec.supportLabel,
                symbol: "envelope",
                destination: PersonalExternalSupportLinks.supportURL(for: locale)
            ),
            .init(
                title: PersonalVisualRefillSpec.privacyPolicyLabel,
                symbol: "shield.lefthalf.filled",
                destination: PersonalExternalSupportLinks.privacyPolicyURL(for: locale)
            ),
            .init(
                title: PersonalVisualRefillSpec.termsLabel,
                symbol: "doc.text",
                destination: PersonalExternalSupportLinks.termsURL(for: locale)
            ),
            .init(
                title: PersonalVisualRefillSpec.sourcesAndLicensesLabel,
                symbol: "text.document",
                destination: nil,
                licenseNotice: .sourcesAndLicenses
            )
        ]
    }

    private var appearancePreference: AppAppearancePreference {
        AppAppearancePreference.resolve(rawValue: appearanceRawValue)
    }

    private var appearanceSelection: Binding<AppAppearancePreference> {
        Binding(
            get: { appearancePreference },
            set: { appearanceRawValue = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: PersonalLayout.sectionSpacing) {
                gallerySection
                informationSection
            }
            .appScreenPadding()
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .sheet(item: $presentedLicenseNotice) { notice in
            PersonalLicenseNoticeView(notice: notice, theme: theme)
        }
    }

    private var metrics: PersonalGalleryMetrics {
        PersonalGalleryMetrics.from(cards: cards)
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(PersonalVisualRefillSpec.title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(theme.primaryText)

            PersonalDiscoveryMetricCard(
                value: "\(metrics.totalDiscoveries)",
                label: PersonalVisualRefillSpec.discoveriesLabel,
                unitLabel: PersonalVisualRefillSpec.discoveryUnitLabel,
                theme: theme
            )

            HStack(alignment: .top, spacing: AppLayout.compactCardGap) {
                PersonalValueCard(
                    value: "\(metrics.thisMonth)",
                    caption: PersonalVisualRefillSpec.thisMonthLabel,
                    theme: theme
                )

                PersonalValueCard(
                    value: "\(metrics.mastered)",
                    caption: PersonalVisualRefillSpec.masteredLabel,
                    theme: theme
                )
            }
        }
    }

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(PersonalVisualRefillSpec.informationLabel)
                .font(AppTypography.labelSmall.weight(.bold))
                .tracking(AppTypography.labelTracking)
                .foregroundStyle(theme.cardSecondaryText)
                .textCase(.uppercase)

            VStack(spacing: PersonalLayout.rowSpacing) {
                appearanceRow

                ForEach(supportRows) { row in
                    PersonalSupportRow(row: row, theme: theme) {
                        present(row)
                    }
                }
            }
            .background(theme.keepsakeCard)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.compactKeepsakeCardCornerRadius, style: .continuous))
            .appAmbientDepth(theme: theme, depth: .card, yOffset: 4)
        }
    }

    private var appearanceRow: some View {
        Menu {
            Picker(PersonalAppearanceSpec.title, selection: appearanceSelection) {
                ForEach(AppAppearancePreference.allCases) { preference in
                    Text(PersonalAppearanceSpec.title(for: preference))
                        .tag(preference)
                }
            }
        } label: {
            HStack(spacing: AppLayout.contentSpacing) {
                ZStack {
                    Circle()
                        .fill(theme.galleryBand.opacity(0.86))
                        .frame(width: 30, height: 30)

                    Image(systemName: "circle.lefthalf.filled")
                        .font(AppTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                }

                Text(PersonalAppearanceSpec.title)
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(PersonalAppearanceSpec.title(for: appearancePreference))
                    .font(AppTypography.bodySmall.weight(.medium))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.up.chevron.down")
                    .font(AppTypography.labelSmall.weight(.medium))
                    .foregroundStyle(theme.secondaryText.opacity(0.45))
            }
            .padding(.horizontal, 16)
            .frame(minHeight: AppLayout.listRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PersonalAppearanceSpec.title)
        .accessibilityValue(PersonalAppearanceSpec.title(for: appearancePreference))
    }

    private func present(_ row: PersonalSupportRowData) {
        if let licenseNotice = row.licenseNotice {
            presentedLicenseNotice = licenseNotice
        }
    }
}

private struct PersonalValueCard: View {
    let value: String
    let caption: String
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AppTypography.displaySmall.weight(.bold))
                .foregroundStyle(theme.primaryText)
                .contentTransition(.numericText())

            Text(caption)
                .font(AppTypography.bodySmall.weight(.medium))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: PersonalLayout.compactCardHeight, alignment: .topLeading)
        .padding(18)
        .appKeepsakeCardSurface(theme: theme, cornerRadius: AppLayout.compactKeepsakeCardCornerRadius)
    }
}

private struct PersonalDiscoveryMetricCard: View {
    let value: String
    let label: String
    let unitLabel: String
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 8) {
                Circle()
                    .fill(theme.lensMuted.opacity(0.72))
                    .frame(width: 22, height: 22)
                    .overlay {
                        Circle()
                            .stroke(theme.lensAccent.opacity(0.1), lineWidth: 1)
                    }

                Text(label.uppercased())
                    .font(AppTypography.labelSmall.weight(.bold))
                    .tracking(AppTypography.labelTracking)
                    .foregroundStyle(theme.lensAccent)
            }

            HStack(alignment: .lastTextBaseline, spacing: 9) {
                Text(value)
                    .font(AppTypography.displayXLarge.weight(.bold))
                    .tracking(AppTypography.displayMetricTracking)
                    .foregroundStyle(theme.primaryText)
                    .contentTransition(.numericText())

                Text(unitLabel)
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .padding(24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value) \(unitLabel)")
        .background {
            RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.keepsakeCardRaised,
                            theme.keepsakeCard,
                            theme.galleryBand.opacity(0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .trailing) {
                    PersonalLensRingDecoration(theme: theme)
                        .offset(x: 54, y: 6)
                }
            }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.keepsakeCardCornerRadius, style: .continuous))
        .appAmbientDepth(theme: theme, depth: .elevated, yOffset: 6)
    }
}

private struct PersonalLensRingDecoration: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.lensMuted.opacity(0.32), lineWidth: 24)
                .frame(width: 172, height: 172)

            Circle()
                .stroke(theme.keepsakeCardRaised.opacity(0.72), lineWidth: 2)
                .frame(width: 126, height: 126)

            Circle()
                .stroke(theme.keepsakeCardRaised.opacity(0.38), lineWidth: 18)
                .frame(width: 104, height: 104)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.keepsakeCardRaised.opacity(0.86),
                            theme.lensMuted.opacity(0.72),
                            theme.lensAccent.opacity(0.92),
                            theme.primaryText.opacity(0.95)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 52
                    )
                )
                .frame(width: 72, height: 72)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(theme.keepsakeCardRaised.opacity(0.84))
                        .frame(width: 10, height: 10)
                        .offset(x: 21, y: 18)
                }
                .shadow(color: theme.lensAccent.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .rotationEffect(.degrees(-8))
        .accessibilityHidden(true)
    }
}

struct PersonalLicenseNotice: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let links: [PersonalLicenseLink]

    static var sourcesAndLicenses: PersonalLicenseNotice {
        PersonalLicenseNotice(
            id: "sources-and-licenses",
            title: AppL10n.Personal.sourcesAndLicenses,
            body: AppL10n.Personal.sourcesAndLicensesBody,
            links: [
                PersonalLicenseLink(
                    title: AppL10n.Personal.edrdgLicense,
                    url: URL(string: "https://www.edrdg.org/edrdg/licence.html")!
                ),
                PersonalLicenseLink(
                    title: AppL10n.Personal.jmdictProject,
                    url: URL(string: "https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project")!
                ),
                PersonalLicenseLink(
                    title: AppL10n.Personal.ccBySa,
                    url: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!
                ),
                PersonalLicenseLink(
                    title: AppL10n.Personal.siglipModel,
                    url: URL(string: "https://huggingface.co/google/siglip-base-patch16-224")!
                ),
                PersonalLicenseLink(
                    title: AppL10n.Personal.siglipProject,
                    url: URL(string: "https://github.com/google-research/big_vision")!
                ),
                PersonalLicenseLink(
                    title: AppL10n.Personal.apacheLicense,
                    url: URL(string: "https://www.apache.org/licenses/LICENSE-2.0")!
                )
            ]
        )
    }
}

struct PersonalLicenseLink: Equatable, Identifiable {
    var id: URL { url }
    let title: String
    let url: URL
}

private struct PersonalSupportRowData: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let destination: URL?
    var licenseNotice: PersonalLicenseNotice?

    var isActionable: Bool {
        destination != nil || licenseNotice != nil
    }
}

private struct PersonalSupportRow: View {
    @Environment(\.openURL) private var openURL

    let row: PersonalSupportRowData
    let theme: AppTheme
    let onSelect: () -> Void

    var body: some View {
        if row.isActionable {
            Button {
                if let destination = row.destination {
                    openURL(destination)
                } else {
                    onSelect()
                }
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        } else {
            rowContent
                .contentShape(Rectangle())
        }
    }

    private var rowContent: some View {
        HStack(spacing: AppLayout.contentSpacing) {
            ZStack {
                Circle()
                    .fill(theme.galleryBand.opacity(0.86))
                    .frame(width: 30, height: 30)

                Image(systemName: row.symbol)
                    .font(AppTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
            }

            Text(row.title)
                .font(AppTypography.titleSmall)
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if row.isActionable {
                Image(systemName: row.destination == nil ? "chevron.right" : "arrow.up.right")
                    .font(AppTypography.labelSmall.weight(.medium))
                    .foregroundStyle(theme.secondaryText.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: AppLayout.listRowHeight)
    }
}

private struct PersonalLicenseNoticeView: View {
    @Environment(\.dismiss) private var dismiss

    let notice: PersonalLicenseNotice
    let theme: AppTheme

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.contentSpacing) {
                    Text(notice.body)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(theme.primaryText)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: PersonalLayout.rowSpacing) {
                        ForEach(notice.links) { link in
                            Link(destination: link.url) {
                                HStack(spacing: AppLayout.contentSpacing) {
                                    Image(systemName: "link")
                                        .font(AppTypography.titleSmall.weight(.medium))
                                        .foregroundStyle(theme.secondaryText)
                                        .frame(width: 20)

                                    Text(link.title)
                                        .font(AppTypography.titleSmall)
                                        .foregroundStyle(theme.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Image(systemName: "arrow.up.right")
                                        .font(AppTypography.labelSmall.weight(.medium))
                                        .foregroundStyle(theme.secondaryText.opacity(0.55))
                                }
                                .padding(.horizontal, AppLayout.cardContentPadding)
                                .frame(height: AppLayout.listRowHeight)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(theme.profileSupportSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.nestedCardCornerRadius, style: .continuous))
                }
                .appScreenPadding()
            }
            .background(theme.background)
            .navigationTitle(notice.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PersonalView()
        .background(AppTheme().background)
        .modelContainer(PreviewModelContainer.shared)
}
