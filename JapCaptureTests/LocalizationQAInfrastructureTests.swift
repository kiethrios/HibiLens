import AppFamilyLocalizationQA
import Foundation
import XCTest

final class LocalizationQAInfrastructureTests: XCTestCase {
    func testAppFamilyFoundationSourcesContainNoAppSpecificVocabulary() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = repositoryRoot
            .appendingPathComponent("Packages/AppFamilyFoundation/Sources")
        let forbiddenVocabulary = [
            "JapCapture",
            "Hibi Lens",
            "AppL10n",
            "VocabularyCard",
            "StudyProgress",
            "CaptureDraft",
            "JMdict",
            "SigLIP",
            "Keepsake",
            "ReviewCard",
            "japaneseHero",
            "translationMetadata"
        ]

        let violations = try appSpecificVocabularyViolations(
            under: sourcesRoot,
            forbiddenVocabulary: forbiddenVocabulary
        )

        XCTAssertEqual(
            violations,
            [],
            """
            AppFamilyFoundation vocabulary boundary violations:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    func testIdentifierMatchingUsesUnicodeSwiftIdentifierBoundaries() {
        let source = """
        let 学japaneseHero語 = 1
        let japaneseHero\u{0301} = 2
        let japaneseHero = 3
        """

        XCTAssertEqual(identifierMatchLines("japaneseHero", in: source), [3])
    }

    func testLocalizationQAProductLinksIntoHostTests() {
        XCTAssertTrue(true)
    }

    func testCatalogValidatorAcceptsCompleteConfiguredCatalog() throws {
        let data = Data(
            """
            {
              "sourceLanguage": "en",
              "version": "1.0",
              "strings": {
                "common.greeting": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Hello %@" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": "你好 %@" } }
                  }
                }
              }
            }
            """.utf8
        )
        let configuration = LocalizationCatalogConfiguration(
            expectedSourceLanguage: "en",
            requiredLanguages: ["en", "zh-Hans"],
            expectedTranslatedKeys: ["common.greeting"]
        )

        XCTAssertEqual(
            try LocalizationCatalogValidator.issues(
                in: data,
                configuration: configuration
            ),
            []
        )
    }

    func testCatalogValidatorReportsMissingLanguageEmptyValueAndPlaceholderMismatch() throws {
        let data = Data(
            """
            {
              "sourceLanguage": "en",
              "version": "1.0",
              "strings": {
                "common.empty": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Value" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": " " } }
                  }
                },
                "common.format": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Hello %@" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": "你好" } }
                  }
                },
                "common.missing": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Missing" } }
                  }
                }
              }
            }
            """.utf8
        )
        let configuration = LocalizationCatalogConfiguration(
            expectedSourceLanguage: "en",
            requiredLanguages: ["en", "zh-Hans"],
            expectedTranslatedKeys: ["common.empty", "common.format", "common.missing"]
        )

        XCTAssertEqual(
            try LocalizationCatalogValidator.issues(in: data, configuration: configuration),
            [
                .emptyValue(key: "common.empty", language: "zh-Hans", variation: "stringUnit"),
                .placeholderMismatch(
                    key: "common.format",
                    language: "zh-Hans",
                    variation: "stringUnit",
                    source: ["%@"],
                    translation: []
                ),
                .missingLocalization(key: "common.missing", language: "zh-Hans")
            ]
        )
    }

    func testCatalogValidatorRejectsUnnamespacedExpectedKey() throws {
        let data = Data(
            """
            {
              "sourceLanguage": "en",
              "version": "1.0",
              "strings": {
                "Save": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Save" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": "保存" } }
                  }
                }
              }
            }
            """.utf8
        )
        let configuration = LocalizationCatalogConfiguration(
            expectedSourceLanguage: "en",
            requiredLanguages: ["en", "zh-Hans"],
            expectedTranslatedKeys: ["Save"]
        )

        XCTAssertEqual(
            try LocalizationCatalogValidator.issues(in: data, configuration: configuration),
            [.invalidKeyFormat("Save")]
        )
    }

    func testCatalogValidatorReportsImplicitPlaceholderArgumentOrderMismatch() throws {
        let data = Data(
            """
            {
              "sourceLanguage": "en",
              "version": "1.0",
              "strings": {
                "common.format": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Object %@ count %d" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": "数量 %d 对象 %@" } }
                  }
                }
              }
            }
            """.utf8
        )
        let configuration = LocalizationCatalogConfiguration(
            expectedSourceLanguage: "en",
            requiredLanguages: ["en", "zh-Hans"],
            expectedTranslatedKeys: ["common.format"]
        )

        XCTAssertEqual(
            try LocalizationCatalogValidator.issues(in: data, configuration: configuration),
            [
                .placeholderMismatch(
                    key: "common.format",
                    language: "zh-Hans",
                    variation: "stringUnit",
                    source: ["%@", "%d"],
                    translation: ["%d", "%@"]
                )
            ]
        )
    }

    func testCatalogValidatorAcceptsExplicitlyPositionedPlaceholderReordering() throws {
        let data = Data(
            """
            {
              "sourceLanguage": "en",
              "version": "1.0",
              "strings": {
                "common.format": {
                  "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": "Object %@ count %d" } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": "数量 %2$d 对象 %1$@" } }
                  }
                }
              }
            }
            """.utf8
        )
        let configuration = LocalizationCatalogConfiguration(
            expectedSourceLanguage: "en",
            requiredLanguages: ["en", "zh-Hans"],
            expectedTranslatedKeys: ["common.format"]
        )

        XCTAssertEqual(
            try LocalizationCatalogValidator.issues(in: data, configuration: configuration),
            []
        )
    }

    func testLiteralAuditorFindsEnglishOutsideAllowlist() {
        let findings = SwiftSourceLiteralAuditor.findings(
            in: #"Text("Upgrade to \(planName)")"#,
            path: "Feature.swift",
            configuration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
        )
        XCTAssertEqual(
            findings,
            [
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 1,
                    literal: #"Upgrade to \(planName)"#
                )
            ]
        )
    }

    func testLiteralAuditorIgnoresCommentsInterpolationOnlyAndAllowlistedValues() {
        let source = #"""
        // Text("Comment only")
        Text("\(count)")
        Image(systemName: "camera")
        """#
        let findings = SwiftSourceLiteralAuditor.findings(
            in: source,
            path: "Feature.swift",
            configuration: SwiftLiteralAuditConfiguration(
                allowedLiterals: ["camera"]
            )
        )
        XCTAssertEqual(findings, [])
    }

    func testLiteralAuditorHandlesMultilineAndNestedBlockComments() {
        let source = #"""
        /*
          /* Text("Nested comment") */
        */
        Text("""
        Upgrade now
        """)
        """#

        XCTAssertEqual(
            SwiftSourceLiteralAuditor.findings(
                in: source,
                path: "Feature.swift",
                configuration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
            ),
            [
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 4,
                    literal: "\nUpgrade now\n"
                )
            ]
        )
    }

    func testLiteralAuditorParsesRawSingleAndMultilineStringDelimiters() {
        let source = ###"""
        let single = #"He said "Upgrade" to \#(name)"#
        let double = ##"Status "ready" \##(count)"##
        let multiline = ##"""
        First "quoted" line
        \##(value)
        """##
        """###

        let literals = SwiftSourceLiteralAuditor.literals(in: source)

        XCTAssertEqual(
            literals.map(\.text),
            [
                "He said \"Upgrade\" to \\#(name)",
                "Status \"ready\" \\##(count)",
                "\nFirst \"quoted\" line\n\\##(value)\n"
            ]
        )
        XCTAssertEqual(literals.map(\.line), [1, 2, 3])
    }

    func testLiteralAuditorPreservesEscapedRawQuotesThatResembleClosingDelimiters() {
        let source = ###"""
        let single = #"a \#"# b"#
        let double = ##"c \##"## d"##
        """###
        let literals = SwiftSourceLiteralAuditor.literals(in: source)

        XCTAssertEqual(literals.map(\.text), ["a \\#\"# b", "c \\##\"## d"])
        XCTAssertEqual(literals.map(\.line), [1, 2])
    }

    func testLiteralAuditorHandlesRawInterpolationAndSourceComments() {
        let source = ###"""
        // Text(#"Comment only"#)
        /* Text(##"Block comment"##) */
        Text(#"\#(value)"#)
        Text(#"Upgrade \#(label("pro")) now"#)
        Text(##"\##(value)"##)
        Text(##"Ready \##(value)"##)
        """###

        XCTAssertEqual(
            SwiftSourceLiteralAuditor.findings(
                in: source,
                path: "Feature.swift",
                configuration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
            ),
            [
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 4,
                    literal: "Upgrade \\#(label(\"pro\")) now"
                ),
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 6,
                    literal: "Ready \\##(value)"
                )
            ]
        )
    }

    func testLiteralAuditorHandlesCommentsInsideRegularAndRawInterpolations() {
        let source = ###"""
        Text("Prefix \(value /* ) "comment" */) suffix")
        Text(#"Ready \#(value /* ) "comment" /* nested ( */ */) now"#)
        Text(##"""
        \##(value // ) "comment"
        )
        """##)
        """###

        XCTAssertEqual(
            SwiftSourceLiteralAuditor.findings(
                in: source,
                path: "Feature.swift",
                configuration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
            ),
            [
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 1,
                    literal: "Prefix \\(value /* ) \"comment\" */) suffix"
                ),
                SwiftLiteralFinding(
                    path: "Feature.swift",
                    line: 2,
                    literal: "Ready \\#(value /* ) \"comment\" /* nested ( */ */) now"
                )
            ]
        )
    }

    func testSourceFileExclusionsMatchPathsRelativeToSourceRoot() throws {
        let fileManager = FileManager.default
        let sourceRoot = fileManager.temporaryDirectory
            .appendingPathComponent("Generated-root-\(UUID().uuidString)")
        defer {
            try? fileManager.removeItem(at: sourceRoot)
        }

        let includedDirectory = sourceRoot.appendingPathComponent("Features")
        let excludedDirectory = includedDirectory.appendingPathComponent("Generated")
        try fileManager.createDirectory(
            at: excludedDirectory,
            withIntermediateDirectories: true
        )
        let includedFile = includedDirectory.appendingPathComponent("Visible.swift")
        let excludedFile = excludedDirectory.appendingPathComponent("Hidden.swift")
        try #"Text("Visible")"#.write(to: includedFile, atomically: true, encoding: .utf8)
        try #"Text("Hidden")"#.write(to: excludedFile, atomically: true, encoding: .utf8)

        let files = try SwiftSourceLiteralAuditor.sourceFiles(
            configuration: SwiftSourceTreeAuditConfiguration(
                sourceRoot: sourceRoot,
                excludedPathSubstrings: ["Generated"],
                literalConfiguration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
            )
        )

        XCTAssertEqual(files, [includedFile])
    }

    func testSourceFileExclusionsAcceptLeadingSlashRelativePatterns() throws {
        let fileManager = FileManager.default
        let sourceRoot = fileManager.temporaryDirectory
            .appendingPathComponent("Leading-slash-root-\(UUID().uuidString)")
        defer {
            try? fileManager.removeItem(at: sourceRoot)
        }

        let includedFile = sourceRoot
            .appendingPathComponent("Views")
            .appendingPathComponent("Feature.swift")
        let excludedFiles = [
            sourceRoot
                .appendingPathComponent("Views")
                .appendingPathComponent("DesignPreview")
                .appendingPathComponent("File.swift"),
            sourceRoot
                .appendingPathComponent("App")
                .appendingPathComponent("PreviewModelContainer.swift"),
            sourceRoot
                .appendingPathComponent("Localization")
                .appendingPathComponent("AppL10n.swift")
        ]

        for file in [includedFile] + excludedFiles {
            try fileManager.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try #"Text("Visible")"#.write(
                to: file,
                atomically: true,
                encoding: .utf8
            )
        }

        let files = try SwiftSourceLiteralAuditor.sourceFiles(
            configuration: SwiftSourceTreeAuditConfiguration(
                sourceRoot: sourceRoot,
                excludedPathSubstrings: [
                    "/Views/DesignPreview/",
                    "/App/PreviewModelContainer.swift",
                    "/Localization/AppL10n.swift"
                ],
                literalConfiguration: SwiftLiteralAuditConfiguration(allowedLiterals: [])
            )
        )

        XCTAssertEqual(files, [includedFile])
    }

    private func appSpecificVocabularyViolations(
        under sourcesRoot: URL,
        forbiddenVocabulary: [String]
    ) throws -> [String] {
        let sourceFiles = try swiftSourceFiles(under: sourcesRoot)
        var violations: [String] = []

        for sourceFile in sourceFiles {
            let source = try String(contentsOf: sourceFile, encoding: .utf8)
            let relativePath = sourceFile.path
                .dropFirst(sourcesRoot.path.count)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            for forbidden in forbiddenVocabulary {
                for literal in SwiftSourceLiteralAuditor.literals(in: source)
                where literal.text.contains(forbidden) {
                    violations.append(
                        "\(relativePath):\(literal.line): \(forbidden) (string literal)"
                    )
                }

                guard isSwiftIdentifier(forbidden) else {
                    continue
                }
                for line in identifierMatchLines(forbidden, in: source) {
                    violations.append(
                        "\(relativePath):\(line): \(forbidden) (identifier)"
                    )
                }
            }
        }

        return violations.sorted()
    }

    private func swiftSourceFiles(under root: URL) throws -> [URL] {
        var directories = [root]
        var swiftFiles: [URL] = []

        while let directory = directories.popLast() {
            let children = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey]
            )
            for child in children {
                let values = try child.resourceValues(
                    forKeys: [.isDirectoryKey, .isRegularFileKey]
                )
                if values.isDirectory == true {
                    directories.append(child)
                } else if values.isRegularFile == true,
                          child.pathExtension == "swift" {
                    swiftFiles.append(child)
                }
            }
        }

        return swiftFiles.sorted { $0.path < $1.path }
    }

    private func isSwiftIdentifier(_ value: String) -> Bool {
        guard let first = value.unicodeScalars.first,
              CharacterSet.letters.union(
                  CharacterSet(charactersIn: "_")
              ).contains(first) else {
            return false
        }
        return value.unicodeScalars.dropFirst().allSatisfy {
            CharacterSet.alphanumerics.union(
                CharacterSet(charactersIn: "_")
            ).contains($0)
        }
    }

    private func identifierMatchLines(_ identifier: String, in source: String) -> [Int] {
        let escapedIdentifier = NSRegularExpression.escapedPattern(
            for: identifier
        )
        guard let expression = try? NSRegularExpression(
            pattern: "(?<![\\p{L}\\p{M}\\p{N}_])\(escapedIdentifier)(?![\\p{L}\\p{M}\\p{N}_])"
        ) else {
            return []
        }

        let sourceRange = NSRange(source.startIndex..., in: source)
        return expression.matches(in: source, range: sourceRange).compactMap { match in
            guard let matchRange = Range(match.range, in: source) else {
                return nil
            }
            return source[..<matchRange.lowerBound].reduce(into: 1) { line, character in
                if character == "\n" {
                    line += 1
                }
            }
        }
    }
}
