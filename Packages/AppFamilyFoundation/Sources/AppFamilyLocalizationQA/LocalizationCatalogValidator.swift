import Foundation

public struct LocalizationCatalogConfiguration: Equatable {
    public let expectedSourceLanguage: String
    public let requiredLanguages: Set<String>
    public let expectedTranslatedKeys: Set<String>
    public let keyPattern: String

    public init(
        expectedSourceLanguage: String,
        requiredLanguages: Set<String>,
        expectedTranslatedKeys: Set<String>,
        keyPattern: String = #"^[a-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$"#
    ) {
        self.expectedSourceLanguage = expectedSourceLanguage
        self.requiredLanguages = requiredLanguages
        self.expectedTranslatedKeys = expectedTranslatedKeys
        self.keyPattern = keyPattern
    }
}

public enum LocalizationCatalogIssue: Equatable {
    case sourceLanguageMismatch(expected: String, actual: String?)
    case missingKey(String)
    case unexpectedTranslatedKey(String)
    case invalidKeyFormat(String)
    case missingLocalization(key: String, language: String)
    case nonTranslatedState(key: String, language: String, variation: String, state: String?)
    case emptyValue(key: String, language: String, variation: String)
    case missingVariation(key: String, language: String, variation: String)
    case placeholderMismatch(
        key: String,
        language: String,
        variation: String,
        source: [String],
        translation: [String]
    )
}

public enum LocalizationCatalogValidator {
    public static func issues(
        in data: Data,
        configuration: LocalizationCatalogConfiguration
    ) throws -> [LocalizationCatalogIssue] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let catalog = object as? [String: Any] else {
            throw LocalizationCatalogValidatorError.invalidRoot
        }

        let keyExpression = try NSRegularExpression(pattern: configuration.keyPattern)
        let placeholderExpression = try NSRegularExpression(
            pattern: #"%(?:\d+\$)?[-+# 0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?[hlLzjtq]*[@dDiuUxXoOfeEgGaAcCsSp]"#
        )
        let actualSourceLanguage = catalog["sourceLanguage"] as? String
        let strings = catalog["strings"] as? [String: Any] ?? [:]
        let translatedKeys = Set(
            strings.compactMap { key, value in
                containsTranslatedStringUnit(in: value) ? key : nil
            }
        )

        var issues: [LocalizationCatalogIssue] = []
        if actualSourceLanguage != configuration.expectedSourceLanguage {
            issues.append(
                .sourceLanguageMismatch(
                    expected: configuration.expectedSourceLanguage,
                    actual: actualSourceLanguage
                )
            )
        }

        let comparedKeys = configuration.expectedTranslatedKeys.union(translatedKeys)
        for key in comparedKeys.sorted() {
            let isExpected = configuration.expectedTranslatedKeys.contains(key)
            let isTranslated = translatedKeys.contains(key)

            if isExpected, !isTranslated {
                issues.append(.missingKey(key))
            } else if isTranslated, !isExpected {
                issues.append(.unexpectedTranslatedKey(key))
            }

            guard isExpected else { continue }

            if !matchesEntireString(key, expression: keyExpression) {
                issues.append(.invalidKeyFormat(key))
            }

            guard let entry = strings[key] as? [String: Any] else { continue }
            let localizations = entry["localizations"] as? [String: Any] ?? [:]
            let sourceLocalization = localizations[configuration.expectedSourceLanguage]
                as? [String: Any]
            let sourceVariations = sourceLocalization.map {
                collectStringUnits(in: $0)
            } ?? [:]

            for language in configuration.requiredLanguages.sorted() {
                guard let localization = localizations[language] as? [String: Any] else {
                    issues.append(.missingLocalization(key: key, language: language))
                    continue
                }

                let variations = collectStringUnits(in: localization)
                if language == configuration.expectedSourceLanguage, variations.isEmpty {
                    issues.append(
                        .missingVariation(
                            key: key,
                            language: language,
                            variation: "stringUnit"
                        )
                    )
                    continue
                }

                for variation in sourceVariations.keys.sorted() {
                    guard let unit = variations[variation] else {
                        issues.append(
                            .missingVariation(
                                key: key,
                                language: language,
                                variation: variation
                            )
                        )
                        continue
                    }

                    if unit.state != "translated" {
                        issues.append(
                            .nonTranslatedState(
                                key: key,
                                language: language,
                                variation: variation,
                                state: unit.state
                            )
                        )
                    }

                    let value = unit.value ?? ""
                    if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        issues.append(
                            .emptyValue(
                                key: key,
                                language: language,
                                variation: variation
                            )
                        )
                    }

                    let sourceValue = sourceVariations[variation]?.value ?? ""
                    let sourcePlaceholders = placeholderTokens(
                        in: sourceValue,
                        expression: placeholderExpression
                    )
                    let translationPlaceholders = placeholderTokens(
                        in: value,
                        expression: placeholderExpression
                    )
                    if placeholderSignature(for: sourcePlaceholders)
                        != placeholderSignature(for: translationPlaceholders) {
                        issues.append(
                            .placeholderMismatch(
                                key: key,
                                language: language,
                                variation: variation,
                                source: sourcePlaceholders,
                                translation: translationPlaceholders
                            )
                        )
                    }
                }
            }
        }

        return issues
    }

    private struct StringUnit {
        let state: String?
        let value: String?
    }

    private struct PlaceholderSignatureComponent: Equatable {
        let slot: Int
        let semantics: String
    }

    private static func containsTranslatedStringUnit(in value: Any) -> Bool {
        if let dictionary = value as? [String: Any] {
            for key in dictionary.keys.sorted() {
                guard let child = dictionary[key] else { continue }
                if key == "stringUnit",
                   let stringUnit = child as? [String: Any],
                   stringUnit["state"] as? String == "translated" {
                    return true
                }
                if containsTranslatedStringUnit(in: child) {
                    return true
                }
            }
        } else if let array = value as? [Any] {
            return array.contains(where: containsTranslatedStringUnit(in:))
        }

        return false
    }

    private static func collectStringUnits(
        in value: Any,
        path: [String] = []
    ) -> [String: StringUnit] {
        var units: [String: StringUnit] = [:]

        if let dictionary = value as? [String: Any] {
            for key in dictionary.keys.sorted() {
                guard let child = dictionary[key] else { continue }
                let childPath = path + [key]
                if key == "stringUnit", let stringUnit = child as? [String: Any] {
                    units[childPath.joined(separator: ".")] = StringUnit(
                        state: stringUnit["state"] as? String,
                        value: stringUnit["value"] as? String
                    )
                } else {
                    units.merge(
                        collectStringUnits(in: child, path: childPath),
                        uniquingKeysWith: { _, replacement in replacement }
                    )
                }
            }
        } else if let array = value as? [Any] {
            for (index, child) in array.enumerated() {
                units.merge(
                    collectStringUnits(in: child, path: path + ["[\(index)]"]),
                    uniquingKeysWith: { _, replacement in replacement }
                )
            }
        }

        return units
    }

    private static func matchesEntireString(
        _ value: String,
        expression: NSRegularExpression
    ) -> Bool {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.firstMatch(in: value, range: range)?.range == range
    }

    private static func placeholderTokens(
        in value: String,
        expression: NSRegularExpression
    ) -> [String] {
        let unescapedValue = value.replacingOccurrences(of: "%%", with: "")
        let range = NSRange(
            unescapedValue.startIndex..<unescapedValue.endIndex,
            in: unescapedValue
        )
        return expression.matches(in: unescapedValue, range: range)
            .compactMap { match in
                Range(match.range, in: unescapedValue).map {
                    String(unescapedValue[$0])
                }
            }
    }

    private static func placeholderSignature(
        for tokens: [String]
    ) -> [PlaceholderSignatureComponent] {
        var nextImplicitSlot = 1
        return tokens.map { token in
            let tokenBody = token.dropFirst()
            let positionalDigits = tokenBody.prefix { $0.isNumber }
            let positionEnd = tokenBody.index(
                tokenBody.startIndex,
                offsetBy: positionalDigits.count
            )

            if !positionalDigits.isEmpty,
               positionEnd < tokenBody.endIndex,
               tokenBody[positionEnd] == "$",
               let slot = Int(positionalDigits) {
                let semanticsStart = tokenBody.index(after: positionEnd)
                return PlaceholderSignatureComponent(
                    slot: slot,
                    semantics: "%" + tokenBody[semanticsStart...]
                )
            }

            defer { nextImplicitSlot += 1 }
            return PlaceholderSignatureComponent(
                slot: nextImplicitSlot,
                semantics: token
            )
        }
        .sorted {
            if $0.slot != $1.slot {
                return $0.slot < $1.slot
            }
            return $0.semantics < $1.semantics
        }
    }
}

private enum LocalizationCatalogValidatorError: LocalizedError {
    case invalidRoot

    var errorDescription: String? {
        switch self {
        case .invalidRoot:
            return "The localization catalog root must be a JSON dictionary."
        }
    }
}
