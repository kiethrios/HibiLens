import AppFamilyLocalizationQA
import XCTest

final class ProductionLocalizationCoverageTests: XCTestCase {
    func testProductionCoverageDoesNotExcludeStyleImplementationFiles() throws {
        let productionPaths = try SwiftSourceLiteralAuditor.sourceFiles(
            configuration: HibiLensLocalizationQAConfiguration.sourceTree(
                projectRoot: projectRoot()
            )
        ).map(\.path)

        XCTAssertTrue(productionPaths.contains { $0.hasSuffix("/Styling/AppButtonStyles.swift") })
        XCTAssertTrue(productionPaths.contains { $0.hasSuffix("/Styling/AppInputStyles.swift") })
    }

    func testProductionSwiftDoesNotIntroduceUnlocalizedEnglishUIStrings() throws {
        let findings = try SwiftSourceLiteralAuditor.findings(
            configuration: HibiLensLocalizationQAConfiguration.sourceTree(
                projectRoot: projectRoot()
            )
        )

        XCTAssertEqual(
            findings,
            [],
            """
            Move user-facing English strings into AppL10n/Localizable.xcstrings \
            or add non-UI literals to the Hibi Lens allowlist:
            \(findings.map { "\($0.path):\($0.line): \($0.literal)" }.joined(separator: "\n"))
            """
        )
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
