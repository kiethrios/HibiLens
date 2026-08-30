import XCTest
@testable import JapCapture

final class JapaneseVocabularyLookupTests: XCTestCase {
    func testLookupMatchesCanonicalLabelAndReturnsCandidateMetadata() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: ["Cup"], limit: 5)

        XCTAssertEqual(candidates.map(\.japanese), ["コップ", "マグカップ"])
        XCTAssertEqual(candidates.first?.kana, "コップ")
        XCTAssertEqual(candidates.first?.romaji, "koppu")
        XCTAssertEqual(candidates.first?.english, "cup")
        XCTAssertEqual(candidates.first?.zhHans, "杯子")
    }

    func testLookupMatchesAliasAfterNormalization() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: [" coffee   cup "], limit: 5)

        XCTAssertEqual(candidates.first?.japanese, "マグカップ")
    }

    func testLookupRemovesParentheticalDisambiguator() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: ["Ball (Object)"], limit: 5)

        XCTAssertEqual(candidates.first?.japanese, "ボール")
    }

    func testLookupUsesRecognizerOrderWhenPriorityTies() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: ["chair", "cup"], limit: 2)

        XCTAssertEqual(candidates.map(\.japanese), ["椅子", "コップ"])
    }

    func testLookupDeduplicatesJapaneseFormsAcrossLabels() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: ["cup", "drinking cup"], limit: 5)

        XCTAssertEqual(candidates.map(\.japanese), ["コップ", "マグカップ"])
    }

    func testLookupReturnsEmptyArrayWhenNoLabelsMatch() throws {
        let lookup = try BundledJapaneseVocabularyLookup(jsonData: Self.fixtureData)

        let candidates = lookup.lookup(labels: ["unknown object"], limit: 5)

        XCTAssertTrue(candidates.isEmpty)
    }

    func testVocabularyCandidateConvertsToCaptureMetadataDraft() {
        let candidate = VocabularyCandidate(
            jmdictSeq: "1467640",
            japanese: "猫",
            kana: "ねこ",
            romaji: "neko",
            english: "cat",
            zhHans: "猫",
            partOfSpeech: ["noun"],
            priority: 90
        )

        let metadata = candidate.captureMetadataDraft()

        XCTAssertEqual(metadata.japaneseText, "猫")
        XCTAssertEqual(metadata.kanaText, "ねこ")
        XCTAssertEqual(metadata.kanjiText, "猫")
        XCTAssertEqual(metadata.romajiText, "neko")
        XCTAssertEqual(metadata.translationEnglish, "cat")
        XCTAssertEqual(metadata.translationChinese, "猫")
    }

    func testVocabularyCandidateUsesEnglishFallbackWhenChineseIsMissing() {
        let candidate = VocabularyCandidate(
            jmdictSeq: "1280530",
            japanese: "硬貨",
            kana: "こうか",
            romaji: "kouka",
            english: "coin",
            zhHans: "",
            partOfSpeech: ["noun"],
            priority: 80
        )

        let metadata = candidate.captureMetadataDraft()

        XCTAssertEqual(metadata.translationEnglish, "coin")
        XCTAssertEqual(metadata.translationChinese, "coin")
    }

    func testBundledVocabularyContainsExpandedOpenImagesObjects() throws {
        let lookup = try BundledJapaneseVocabularyLookup()

        XCTAssertEqual(lookup.lookup(labels: ["box"], limit: 1).first?.japanese, "箱")
        XCTAssertEqual(lookup.lookup(labels: ["fork"], limit: 1).first?.japanese, "フォーク")
        XCTAssertEqual(lookup.lookup(labels: ["belt"], limit: 1).first?.japanese, "ベルト")
        XCTAssertEqual(lookup.lookup(labels: ["soundbox"], limit: 1).first?.japanese, "スピーカー")
        XCTAssertEqual(lookup.lookup(labels: ["xbox controller"], limit: 1).first?.japanese, "ゲームコントローラー")
    }

    private static let fixtureData = """
    {
      "version": 1,
      "sources": [],
      "aliases": {
        "ball": ["ball"],
        "chair": ["chair"],
        "coffee cup": ["mug_cup"],
        "cup": ["cup", "mug_cup"],
        "drinking cup": ["cup"]
      },
      "concepts": [
        {
          "id": "cup",
          "domain": "kitchen",
          "canonicalLabel": "cup",
          "priority": 95,
          "candidates": [
            {
              "jmdictSeq": "1050390",
              "japanese": "コップ",
              "kana": "コップ",
              "romaji": "koppu",
              "english": "cup",
              "zhHans": "杯子",
              "partOfSpeech": ["noun"],
              "priority": 95
            }
          ]
        },
        {
          "id": "mug_cup",
          "domain": "kitchen",
          "canonicalLabel": "mug",
          "priority": 94,
          "candidates": [
            {
              "jmdictSeq": "2057330",
              "japanese": "マグカップ",
              "kana": "マグカップ",
              "romaji": "magukappu",
              "english": "mug",
              "zhHans": "马克杯",
              "partOfSpeech": ["noun"],
              "priority": 94
            }
          ]
        },
        {
          "id": "chair",
          "domain": "furniture",
          "canonicalLabel": "chair",
          "priority": 95,
          "candidates": [
            {
              "jmdictSeq": "1157070",
              "japanese": "椅子",
              "kana": "いす",
              "romaji": "isu",
              "english": "chair",
              "zhHans": "椅子",
              "partOfSpeech": ["noun"],
              "priority": 95
            }
          ]
        },
        {
          "id": "ball",
          "domain": "sports",
          "canonicalLabel": "ball",
          "priority": 80,
          "candidates": [
            {
              "jmdictSeq": "1000004",
              "japanese": "ボール",
              "kana": "ボール",
              "romaji": "boru",
              "english": "ball",
              "zhHans": "球",
              "partOfSpeech": ["noun"],
              "priority": 80
            }
          ]
        }
      ]
    }
    """.data(using: .utf8)!
}
