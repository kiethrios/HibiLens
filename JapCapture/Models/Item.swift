//
//  Item.swift
//  JapCapture
//
//  Created by kiethrios on 2026/3/31.
//

import Foundation

struct CaptureItem: Hashable, Identifiable {
    let id: UUID
    let japanese: String
    let english: String
    let romaji: String?
    let kana: String?
    let translation: String?
    let localImagePath: String?
    let thumbnailImagePath: String?
    let imageAspectRatio: Double
    let isPlaceholder: Bool

    init(
        id: UUID = UUID(),
        japanese: String,
        english: String,
        localImagePath: String?,
        thumbnailImagePath: String? = nil,
        imageAspectRatio: Double = 1,
        romaji: String? = nil,
        kana: String? = nil,
        translation: String? = nil
    ) {
        self.id = id
        self.japanese = japanese
        self.english = english
        self.romaji = romaji
        self.kana = kana
        self.translation = translation
        self.localImagePath = localImagePath
        self.thumbnailImagePath = thumbnailImagePath ?? localImagePath
        self.imageAspectRatio = imageAspectRatio
        self.isPlaceholder = false
    }

    init(placeholder: Void = ()) {
        self.id = UUID()
        self.japanese = ""
        self.english = ""
        self.romaji = nil
        self.kana = nil
        self.translation = nil
        self.localImagePath = nil
        self.thumbnailImagePath = nil
        self.imageAspectRatio = 1
        self.isPlaceholder = true
    }
}

struct VocabularyDetailSession: Hashable {
    let items: [CaptureItem]
    let selectedID: UUID?
    let source: VocabularyDetailSource

    init?(
        selected item: CaptureItem,
        in sourceItems: [CaptureItem],
        source: VocabularyDetailSource = .todaysCaptures
    ) {
        guard !item.isPlaceholder else { return nil }

        let realItems = sourceItems.filter { !$0.isPlaceholder }
        guard realItems.contains(where: { $0.id == item.id }) else { return nil }

        self.items = realItems
        self.selectedID = item.id
        self.source = source
    }

    private init(items: [CaptureItem], selectedID: UUID?, source: VocabularyDetailSource) {
        self.items = items
        self.selectedID = selectedID
        self.source = source
    }

    func removingItem(withID removedID: UUID) -> VocabularyDetailSession {
        guard let removedIndex = items.firstIndex(where: { $0.id == removedID }) else {
            return self
        }

        let remainingItems = items.filter { $0.id != removedID }
        let nextSelection = remainingItems[safe: removedIndex]?.id
            ?? remainingItems[safe: removedIndex - 1]?.id

        return VocabularyDetailSession(
            items: remainingItems,
            selectedID: nextSelection,
            source: source
        )
    }
}

struct CaptureCardDisplayContent: Equatable {
    let japanese: String
    let reading: String
    let romaji: String
    let translation: String

    static func from(_ item: CaptureItem) -> CaptureCardDisplayContent {
        CaptureCardDisplayContent(
            japanese: item.japanese,
            reading: item.kana?.trimmedForDisplay ?? item.japanese,
            romaji: item.romaji?.trimmedForDisplay ?? item.english,
            translation: item.translation?.trimmedForDisplay ?? item.english
        )
    }
}

enum ReviewVisualRefillSpec {
    static var learningTabTitle: String { AppL10n.Review.learning }
    static var masteredTabTitle: String { AppL10n.Review.mastered }

    static var learningEmptyTitle: String { AppL10n.Review.learningEmptyTitle }
    static var learningEmptyMessage: String { AppL10n.Review.learningEmptyMessage }
    static var masteredEmptyTitle: String { AppL10n.Review.masteredEmptyTitle }
    static var masteredEmptyMessage: String { AppL10n.Review.masteredEmptyMessage }

    static var deleteAlertTitle: String { AppL10n.Review.deleteAlertTitle }
    static var deleteConfirmTitle: String { AppL10n.Review.deleteConfirmTitle }

    static let columnCount = 2
    static let columnSpacing: CGFloat = 16
    static let segmentedControlHeight: CGFloat = 48
    static let segmentedControlMaxWidth: CGFloat = 384
    static let cardCornerRadius: CGFloat = AppLayout.compactKeepsakeCardCornerRadius
    static let imageMinHeight: CGFloat = 104
    static let imageMaxHeight: CGFloat = 188
}

struct StatisticMetric: Identifiable {
    let id = UUID()
    let value: String
    let title: String
    let subtitle: String?
    let symbol: String
}

enum NavDestination: CaseIterable, Identifiable {
    case home
    case capture
    case review
    case personal

    var id: String {
        switch self {
        case .home: "home"
        case .capture: "capture"
        case .review: "review"
        case .personal: "personal"
        }
    }

    var title: String {
        switch self {
        case .home: AppL10n.Nav.home
        case .capture: AppL10n.Nav.capture
        case .review: AppL10n.Nav.review
        case .personal: AppL10n.Nav.personal
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .capture: "camera"
        case .review: "menucard"
        case .personal: "person"
        }
    }
}

enum ReviewBucket {
    case learned
    case mastered
}

enum VocabularyDetailSource: Hashable {
    case todaysCaptures
    case learningReview
    case masteredReview

    var reviewButtonTitle: String {
        switch self {
        case .todaysCaptures, .learningReview:
            AppL10n.Review.mastered
        case .masteredReview:
            AppL10n.Review.learning
        }
    }

    var removesCardAfterReviewAction: Bool {
        switch self {
        case .todaysCaptures, .learningReview, .masteredReview:
            true
        }
    }
}

extension VocabularyCard {
    func matchesReviewBucket(_ bucket: ReviewBucket) -> Bool {
        switch bucket {
        case .learned:
            return currentStudyState == .new || currentStudyState == .learned
        case .mastered:
            return currentStudyState == .mastered
        }
    }

    func captureItem(languageCode: String? = TranslationDisplayPolicy.preferredLanguageCode()) -> CaptureItem {
        CaptureItem(
            id: id,
            japanese: japaneseText,
            english: translation(forLanguageCode: languageCode).uppercased(),
            localImagePath: imageLocalPath,
            thumbnailImagePath: thumbnailImageLocalPath,
            imageAspectRatio: imageAspectRatio,
            romaji: romajiText,
            kana: kanaText,
            translation: translation(forLanguageCode: languageCode)
        )
    }
}

enum PreviewData {
    static let sampleCaptureItems: [CaptureItem] = [
        CaptureItem(
            japanese: "猫",
            english: "CAT",
            localImagePath: nil,
            romaji: "Neko",
            kana: "ねこ",
            translation: "Cat"
        ),
        CaptureItem(
            japanese: "水",
            english: "WATER",
            localImagePath: nil,
            romaji: "Mizu",
            kana: "みず",
            translation: "Water"
        ),
        CaptureItem(placeholder: ())
    ]
}

private extension String {
    var trimmedForDisplay: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
