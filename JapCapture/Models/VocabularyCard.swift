//
//  VocabularyCard.swift
//  JapCapture
//
//  Created by Codex on 2026/4/17.
//

import Foundation
import SwiftData

@Model
final class VocabularyCard {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var capturedAt: Date
    var imageLocalPath: String
    var thumbnailImageLocalPath: String
    var imageAspectRatio: Double
    var japaneseText: String
    var kanaText: String?
    var kanjiText: String?
    var romajiText: String?
    var translationEnglish: String
    var translationChinese: String
    @Relationship(deleteRule: .cascade) var studyProgress: StudyProgress?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        capturedAt: Date,
        imageLocalPath: String,
        thumbnailImageLocalPath: String? = nil,
        imageAspectRatio: Double = 1,
        japaneseText: String,
        kanaText: String? = nil,
        kanjiText: String? = nil,
        romajiText: String? = nil,
        translationEnglish: String,
        translationChinese: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.capturedAt = capturedAt
        self.imageLocalPath = imageLocalPath
        self.thumbnailImageLocalPath = thumbnailImageLocalPath ?? imageLocalPath
        self.imageAspectRatio = imageAspectRatio
        self.japaneseText = japaneseText
        self.kanaText = kanaText
        self.kanjiText = kanjiText
        self.romajiText = romajiText
        self.translationEnglish = translationEnglish
        self.translationChinese = translationChinese
        self.studyProgress = nil
    }

    func translation(forLanguageCode languageCode: String?) -> String {
        TranslationDisplayPolicy.preferredTranslation(
            english: translationEnglish,
            chinese: translationChinese,
            languageCode: languageCode
        )
    }
}

extension VocabularyCard {
    var currentStudyState: StudyProgressState {
        studyProgress?.state ?? .new
    }

    var reviewBucketToggleTitle: String {
        currentStudyState == .mastered ? AppL10n.Review.learning : AppL10n.Review.mastered
    }

    var isLearned: Bool {
        currentStudyState == .learned
    }

    var isMastered: Bool {
        currentStudyState == .mastered
    }

    func toggleReviewBucket(at date: Date = .now) {
        let progress = studyProgress ?? StudyProgress(cardID: id)
        studyProgress = progress

        if progress.state == .mastered {
            progress.markLearned(at: date)
        } else {
            progress.markMastered(at: date)
        }
    }
}
