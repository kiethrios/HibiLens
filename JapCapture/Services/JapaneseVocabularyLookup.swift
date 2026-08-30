//
//  JapaneseVocabularyLookup.swift
//  JapCapture
//
//  Created by Codex on 2026/4/30.
//

import Foundation

struct VocabularyCandidate: Decodable, Equatable {
    let jmdictSeq: String
    let japanese: String
    let kana: String
    let romaji: String
    let english: String
    let zhHans: String
    let partOfSpeech: [String]
    let priority: Int

    func captureMetadataDraft() -> CaptureMetadataDraft {
        let chineseFallback = zhHans.trimmingCharacters(in: .whitespacesAndNewlines)
        return CaptureMetadataDraft(
            japaneseText: japanese,
            kanaText: kana,
            kanjiText: japanese,
            romajiText: romaji,
            translationEnglish: english,
            translationChinese: chineseFallback.isEmpty ? english : chineseFallback
        )
    }
}

protocol JapaneseVocabularyLookup {
    func lookup(labels: [String], limit: Int) -> [VocabularyCandidate]
}

final class BundledJapaneseVocabularyLookup: JapaneseVocabularyLookup {
    private let aliases: [String: [String]]
    private let conceptsByID: [String: VocabularyConcept]

    init(jsonData: Data) throws {
        let resource = try JSONDecoder().decode(ObjectVocabularyResource.self, from: jsonData)
        aliases = resource.aliases.reduce(into: [:]) { result, item in
            result[Self.normalizedLabel(item.key)] = item.value
        }
        conceptsByID = Dictionary(uniqueKeysWithValues: resource.concepts.map { ($0.id, $0) })
    }

    convenience init(bundle: Bundle = .main, resourceName: String = "object-vocabulary") throws {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw VocabularyLookupError.missingResource(resourceName)
        }
        try self.init(jsonData: Data(contentsOf: url))
    }

    static func bundledOrEmpty() -> JapaneseVocabularyLookup {
        (try? BundledJapaneseVocabularyLookup()) ?? EmptyJapaneseVocabularyLookup()
    }

    func lookup(labels: [String], limit: Int) -> [VocabularyCandidate] {
        guard limit > 0 else { return [] }

        var rankedCandidates: [RankedVocabularyCandidate] = []
        var seenConceptLabelPairs = Set<String>()

        for (labelIndex, label) in labels.enumerated() {
            let normalized = Self.normalizedLabel(label)
            guard !normalized.isEmpty else { continue }
            let conceptIDs = aliases[normalized] ?? []

            for conceptID in conceptIDs {
                guard let concept = conceptsByID[conceptID] else { continue }
                let matchRank = concept.canonicalLabel == normalized ? 0 : 1
                let conceptLabelKey = "\(labelIndex)|\(conceptID)"
                guard seenConceptLabelPairs.insert(conceptLabelKey).inserted else { continue }

                for candidate in concept.candidates {
                    rankedCandidates.append(RankedVocabularyCandidate(
                        candidate: candidate,
                        matchRank: matchRank,
                        conceptPriority: concept.priority,
                        labelIndex: labelIndex
                    ))
                }
            }
        }

        var seenJapanese = Set<String>()
        return rankedCandidates
            .sorted()
            .compactMap { ranked in
                guard seenJapanese.insert(ranked.candidate.japanese).inserted else { return nil }
                return ranked.candidate
            }
            .prefix(limit)
            .map { $0 }
    }

    static func normalizedLabel(_ label: String) -> String {
        let withoutParentheses = label.replacingOccurrences(
            of: #"\s*\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )
        let lowered = withoutParentheses
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return lowered
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private struct ObjectVocabularyResource: Decodable {
    let version: Int
    let sources: [VocabularySource]
    let aliases: [String: [String]]
    let concepts: [VocabularyConcept]
}

private struct VocabularySource: Decodable {
    let name: String
    let license: String
    let url: String
}

private struct VocabularyConcept: Decodable {
    let id: String
    let domain: String
    let canonicalLabel: String
    let priority: Int
    let candidates: [VocabularyCandidate]
}

private struct RankedVocabularyCandidate: Comparable {
    let candidate: VocabularyCandidate
    let matchRank: Int
    let conceptPriority: Int
    let labelIndex: Int

    static func < (lhs: RankedVocabularyCandidate, rhs: RankedVocabularyCandidate) -> Bool {
        if lhs.matchRank != rhs.matchRank {
            return lhs.matchRank < rhs.matchRank
        }
        if lhs.conceptPriority != rhs.conceptPriority {
            return lhs.conceptPriority > rhs.conceptPriority
        }
        if lhs.candidate.priority != rhs.candidate.priority {
            return lhs.candidate.priority > rhs.candidate.priority
        }
        if lhs.labelIndex != rhs.labelIndex {
            return lhs.labelIndex < rhs.labelIndex
        }
        return lhs.candidate.japanese < rhs.candidate.japanese
    }
}

private struct EmptyJapaneseVocabularyLookup: JapaneseVocabularyLookup {
    func lookup(labels: [String], limit: Int) -> [VocabularyCandidate] {
        []
    }
}

enum VocabularyLookupError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let resourceName):
            "Vocabulary resource '\(resourceName).json' is missing from the app bundle."
        }
    }
}
