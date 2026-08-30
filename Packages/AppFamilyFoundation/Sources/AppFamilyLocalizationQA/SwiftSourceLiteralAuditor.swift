import Foundation

public struct SwiftLiteralAuditConfiguration: Equatable {
    public let allowedLiterals: Set<String>
    public let englishWordPattern: String

    public init(
        allowedLiterals: Set<String>,
        englishWordPattern: String = "[A-Za-z]{2,}"
    ) {
        self.allowedLiterals = allowedLiterals
        self.englishWordPattern = englishWordPattern
    }
}

public struct SwiftSourceTreeAuditConfiguration: Equatable {
    public let sourceRoot: URL
    public let excludedPathSubstrings: [String]
    public let literalConfiguration: SwiftLiteralAuditConfiguration

    public init(
        sourceRoot: URL,
        excludedPathSubstrings: [String],
        literalConfiguration: SwiftLiteralAuditConfiguration
    ) {
        self.sourceRoot = sourceRoot
        self.excludedPathSubstrings = excludedPathSubstrings
        self.literalConfiguration = literalConfiguration
    }
}

public struct SwiftSourceLiteral: Equatable {
    public let text: String
    public let line: Int
}

public struct SwiftLiteralFinding: Equatable {
    public let path: String
    public let line: Int
    public let literal: String

    public init(path: String, line: Int, literal: String) {
        self.path = path
        self.line = line
        self.literal = literal
    }
}

public enum SwiftSourceLiteralAuditor {
    public static func literals(in source: String) -> [SwiftSourceLiteral] {
        parsedLiterals(in: source).map(\.literal)
    }

    private struct ParsedSourceLiteral {
        let literal: SwiftSourceLiteral
        let interpolationHashCount: Int
    }

    private struct StringDelimiter {
        let hashCount: Int
        let quoteCount: Int

        var openingLength: Int {
            hashCount + quoteCount
        }
    }

    private static func parsedLiterals(in source: String) -> [ParsedSourceLiteral] {
        let bytes = Array(source.utf8)
        var index = 0
        var line = 1
        var literals: [ParsedSourceLiteral] = []

        while index < bytes.count {
            if hasPrefix([0x2F, 0x2F], in: bytes, at: index) {
                consumeLineComment(in: bytes, index: &index, line: &line)
            } else if hasPrefix([0x2F, 0x2A], in: bytes, at: index) {
                consumeBlockComment(in: bytes, index: &index, line: &line)
            } else if let delimiter = stringDelimiter(in: bytes, at: index) {
                let startLine = line
                if let text = consumeStringLiteral(
                    in: bytes,
                    index: &index,
                    line: &line,
                    delimiter: delimiter
                ) {
                    literals.append(
                        ParsedSourceLiteral(
                            literal: SwiftSourceLiteral(text: text, line: startLine),
                            interpolationHashCount: delimiter.hashCount
                        )
                    )
                }
            } else {
                advance(in: bytes, index: &index, line: &line)
            }
        }

        return literals
    }

    public static func sourceFiles(
        configuration: SwiftSourceTreeAuditConfiguration
    ) throws -> [URL] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: configuration.sourceRoot,
            includingPropertiesForKeys: Array(keys)
        ) else {
            throw SwiftSourceLiteralAuditorError.cannotEnumerate(configuration.sourceRoot)
        }

        return try enumerator.compactMap { item in
            guard let url = item as? URL else { return nil }
            let values = try url.resourceValues(forKeys: keys)
            guard values.isRegularFile == true, url.pathExtension == "swift" else {
                return nil
            }
            let relativePath = relativePath(
                for: url,
                sourceRoot: configuration.sourceRoot
            )
            let rootedRelativePath = "/" + relativePath
            guard !configuration.excludedPathSubstrings.contains(
                where: rootedRelativePath.contains
            ) else {
                return nil
            }
            return url
        }
        .sorted { $0.path < $1.path }
    }

    public static func findings(
        in source: String,
        path: String,
        configuration: SwiftLiteralAuditConfiguration
    ) -> [SwiftLiteralFinding] {
        parsedLiterals(in: source)
            .filter {
                shouldFlag(
                    $0.literal.text,
                    interpolationHashCount: $0.interpolationHashCount,
                    configuration: configuration
                )
            }
            .map {
                SwiftLiteralFinding(
                    path: path,
                    line: $0.literal.line,
                    literal: $0.literal.text
                )
            }
            .sorted(by: findingsAreOrdered)
    }

    public static func findings(
        configuration: SwiftSourceTreeAuditConfiguration
    ) throws -> [SwiftLiteralFinding] {
        let files = try sourceFiles(configuration: configuration)
        var findings: [SwiftLiteralFinding] = []

        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            findings.append(
                contentsOf: self.findings(
                    in: source,
                    path: relativePath(
                        for: file,
                        sourceRoot: configuration.sourceRoot
                    ),
                    configuration: configuration.literalConfiguration
                )
            )
        }

        return findings.sorted(by: findingsAreOrdered)
    }

    private static func shouldFlag(
        _ literal: String,
        interpolationHashCount: Int,
        configuration: SwiftLiteralAuditConfiguration
    ) -> Bool {
        guard !configuration.allowedLiterals.contains(literal) else { return false }
        let staticText = removingInterpolations(
            from: literal,
            interpolationHashCount: interpolationHashCount
        )
        return staticText.range(
            of: configuration.englishWordPattern,
            options: .regularExpression
        ) != nil
    }

    private static func removingInterpolations(
        from literal: String,
        interpolationHashCount: Int
    ) -> String {
        let bytes = Array(literal.utf8)
        var index = 0
        var staticBytes: [UInt8] = []

        while index < bytes.count {
            if isInterpolationStart(
                in: bytes,
                at: index,
                hashCount: interpolationHashCount
            ) {
                index += interpolationHashCount + 2
                skipInterpolation(in: bytes, index: &index)
            } else {
                staticBytes.append(bytes[index])
                index += 1
            }
        }

        return String(decoding: staticBytes, as: UTF8.self)
    }

    private static func skipInterpolation(in bytes: [UInt8], index: inout Int) {
        var parenthesisDepth = 1
        var ignoredLine = 1

        while index < bytes.count, parenthesisDepth > 0 {
            if hasPrefix([0x2F, 0x2F], in: bytes, at: index) {
                consumeLineComment(in: bytes, index: &index, line: &ignoredLine)
                continue
            }
            if hasPrefix([0x2F, 0x2A], in: bytes, at: index) {
                consumeBlockComment(in: bytes, index: &index, line: &ignoredLine)
                continue
            }
            if let delimiter = stringDelimiter(in: bytes, at: index) {
                _ = consumeStringLiteral(
                    in: bytes,
                    index: &index,
                    line: &ignoredLine,
                    delimiter: delimiter
                )
                continue
            }

            if bytes[index] == 0x28 {
                parenthesisDepth += 1
            } else if bytes[index] == 0x29 {
                parenthesisDepth -= 1
            }
            index += 1
        }
    }

    private static func consumeStringLiteral(
        in bytes: [UInt8],
        index: inout Int,
        line: inout Int,
        delimiter: StringDelimiter
    ) -> String? {
        index += delimiter.openingLength
        var content: [UInt8] = []

        while index < bytes.count {
            if isClosingDelimiter(delimiter, in: bytes, at: index) {
                index += delimiter.quoteCount + delimiter.hashCount
                return String(decoding: content, as: UTF8.self)
            }

            if isInterpolationStart(
                in: bytes,
                at: index,
                hashCount: delimiter.hashCount
            ) {
                let interpolationLength = delimiter.hashCount + 2
                content.append(contentsOf: bytes[index..<(index + interpolationLength)])
                index += interpolationLength
                consumeInterpolation(in: bytes, index: &index, line: &line, content: &content)
            } else if delimiter.hashCount == 0, bytes[index] == 0x5C {
                content.append(bytes[index])
                index += 1
                if index < bytes.count {
                    content.append(bytes[index])
                    advance(in: bytes, index: &index, line: &line)
                }
            } else {
                content.append(bytes[index])
                advance(in: bytes, index: &index, line: &line)
            }
        }

        return nil
    }

    private static func consumeInterpolation(
        in bytes: [UInt8],
        index: inout Int,
        line: inout Int,
        content: inout [UInt8]
    ) {
        var parenthesisDepth = 1

        while index < bytes.count, parenthesisDepth > 0 {
            if hasPrefix([0x2F, 0x2F], in: bytes, at: index) {
                let commentStart = index
                consumeLineComment(in: bytes, index: &index, line: &line)
                content.append(contentsOf: bytes[commentStart..<index])
                continue
            }
            if hasPrefix([0x2F, 0x2A], in: bytes, at: index) {
                let commentStart = index
                consumeBlockComment(in: bytes, index: &index, line: &line)
                content.append(contentsOf: bytes[commentStart..<index])
                continue
            }
            if let delimiter = stringDelimiter(in: bytes, at: index) {
                let nestedStart = index
                _ = consumeStringLiteral(
                    in: bytes,
                    index: &index,
                    line: &line,
                    delimiter: delimiter
                )
                content.append(contentsOf: bytes[nestedStart..<index])
                continue
            }

            let byte = bytes[index]
            content.append(byte)
            if byte == 0x28 {
                parenthesisDepth += 1
            } else if byte == 0x29 {
                parenthesisDepth -= 1
            }
            advance(in: bytes, index: &index, line: &line)
        }
    }

    private static func consumeLineComment(
        in bytes: [UInt8],
        index: inout Int,
        line: inout Int
    ) {
        while index < bytes.count {
            let byte = bytes[index]
            advance(in: bytes, index: &index, line: &line)
            if byte == 0x0A { return }
        }
    }

    private static func consumeBlockComment(
        in bytes: [UInt8],
        index: inout Int,
        line: inout Int
    ) {
        var depth = 0

        while index < bytes.count {
            if hasPrefix([0x2F, 0x2A], in: bytes, at: index) {
                depth += 1
                index += 2
            } else if hasPrefix([0x2A, 0x2F], in: bytes, at: index) {
                depth -= 1
                index += 2
                if depth == 0 { return }
            } else {
                advance(in: bytes, index: &index, line: &line)
            }
        }
    }

    private static func advance(
        in bytes: [UInt8],
        index: inout Int,
        line: inout Int
    ) {
        if bytes[index] == 0x0A {
            line += 1
        }
        index += 1
    }

    private static func stringDelimiter(
        in bytes: [UInt8],
        at index: Int
    ) -> StringDelimiter? {
        var cursor = index
        while cursor < bytes.count, bytes[cursor] == 0x23 {
            cursor += 1
        }
        guard cursor < bytes.count, bytes[cursor] == 0x22 else {
            return nil
        }

        let quoteCount = hasPrefix([0x22, 0x22, 0x22], in: bytes, at: cursor) ? 3 : 1
        return StringDelimiter(
            hashCount: cursor - index,
            quoteCount: quoteCount
        )
    }

    private static func isClosingDelimiter(
        _ delimiter: StringDelimiter,
        in bytes: [UInt8],
        at index: Int
    ) -> Bool {
        if isEscapedRawQuote(delimiter, in: bytes, at: index) {
            return false
        }
        let closing = Array(repeating: UInt8(0x22), count: delimiter.quoteCount)
            + Array(repeating: UInt8(0x23), count: delimiter.hashCount)
        return hasPrefix(closing, in: bytes, at: index)
    }

    private static func isEscapedRawQuote(
        _ delimiter: StringDelimiter,
        in bytes: [UInt8],
        at index: Int
    ) -> Bool {
        guard delimiter.hashCount > 0,
              index >= delimiter.hashCount + 1,
              bytes[index - delimiter.hashCount - 1] == 0x5C else {
            return false
        }

        return bytes[(index - delimiter.hashCount)..<index]
            .allSatisfy { $0 == 0x23 }
    }

    private static func isInterpolationStart(
        in bytes: [UInt8],
        at index: Int,
        hashCount: Int
    ) -> Bool {
        let interpolationStart = [UInt8(0x5C)]
            + Array(repeating: UInt8(0x23), count: hashCount)
            + [UInt8(0x28)]
        return hasPrefix(interpolationStart, in: bytes, at: index)
    }

    private static func hasPrefix(
        _ prefix: [UInt8],
        in bytes: [UInt8],
        at index: Int
    ) -> Bool {
        guard index + prefix.count <= bytes.count else { return false }
        return bytes[index..<(index + prefix.count)].elementsEqual(prefix)
    }

    private static func relativePath(for file: URL, sourceRoot: URL) -> String {
        let rootPath = sourceRoot.standardizedFileURL.path
        let filePath = file.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard filePath.hasPrefix(prefix) else { return file.lastPathComponent }
        return String(filePath.dropFirst(prefix.count))
    }

    private static func findingsAreOrdered(
        _ lhs: SwiftLiteralFinding,
        _ rhs: SwiftLiteralFinding
    ) -> Bool {
        if lhs.path != rhs.path {
            return lhs.path < rhs.path
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.literal < rhs.literal
    }
}

private enum SwiftSourceLiteralAuditorError: LocalizedError {
    case cannotEnumerate(URL)

    var errorDescription: String? {
        switch self {
        case .cannotEnumerate(let sourceRoot):
            return "Cannot enumerate Swift source root: \(sourceRoot.path)"
        }
    }
}
