import Foundation
import UIKit

struct CaptureDraft: Identifiable {
    let id = UUID()
    let imageData: Data
    let previewImage: UIImage
    let metadata: CaptureMetadataDraft
}

struct CaptureDraftCandidateSet: Identifiable {
    let id = UUID()
    let drafts: [CaptureDraft]
}

enum CaptureDraftCandidateBuilder {
    static func makeDrafts(labels: [String], imageData: Data, previewImage: UIImage) -> [CaptureDraft] {
        labels.map { label in
            CaptureDraft(
                imageData: imageData,
                previewImage: previewImage,
                metadata: CaptureMetadataDraft.fallbackLabelMetadata(for: label)
            )
        }
    }

    static func makeDrafts(
        candidates: [VocabularyCandidate],
        fallbackLabels: [String],
        imageData: Data,
        previewImage: UIImage
    ) -> [CaptureDraft] {
        if candidates.isEmpty {
            let fallbackLabel = fallbackLabels
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return makeDrafts(
                labels: [fallbackLabel?.isEmpty == false ? fallbackLabel! : "object"],
                imageData: imageData,
                previewImage: previewImage
            )
        }

        return candidates.map { candidate in
            CaptureDraft(
                imageData: imageData,
                previewImage: previewImage,
                metadata: candidate.captureMetadataDraft()
            )
        }
    }
}

struct CaptureMetadataDraft: Equatable {
    let japaneseText: String
    let kanaText: String
    let kanjiText: String
    let romajiText: String
    let translationEnglish: String
    let translationChinese: String

    var isReadyToSave: Bool {
        !japaneseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translationEnglish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translationChinese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var preferredTranslation: String {
        translationEnglish
    }

    static func fallbackLabelMetadata(for label: String) -> CaptureMetadataDraft {
        CaptureMetadataDraft(
            japaneseText: label,
            kanaText: "",
            kanjiText: "",
            romajiText: label,
            translationEnglish: label,
            translationChinese: label
        )
    }

    func optionalTrimmedValue(for keyPath: KeyPath<CaptureMetadataDraft, String>) -> String? {
        let trimmed = self[keyPath: keyPath].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
