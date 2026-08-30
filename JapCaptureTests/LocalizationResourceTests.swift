import AppFamilyLocalizationQA
import XCTest

final class LocalizationResourceTests: XCTestCase {
    fileprivate struct StringCatalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct StringUnit: Decodable {
                    let value: String
                }

                let stringUnit: StringUnit
            }

            let localizations: [String: Localization]?
        }

        let sourceLanguage: String
        let strings: [String: Entry]
        let version: String
    }

    func testLocalizableCatalogContainsApprovedEnglishAndChineseAnchors() throws {
        let catalog = try loadStringCatalog()

        XCTAssertEqual(catalog.sourceLanguage, "en")
        XCTAssertEqual(catalog.version, "1.0")
        XCTAssertEqual(catalog.localizedValue(for: "home.captureNow", language: "en"), "Capture Now")
        XCTAssertEqual(catalog.localizedValue(for: "home.captureNow", language: "zh-Hans"), "拍一个")
        XCTAssertEqual(catalog.localizedValue(for: "home.keepsakes.title", language: "zh-Hans"), "我的收藏")
        XCTAssertEqual(catalog.localizedValue(for: "personal.wordsCaptured", language: "en"), "Words Captured")
        XCTAssertEqual(catalog.localizedValue(for: "personal.wordsCaptured", language: "zh-Hans"), "已拍词条")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance", language: "en"), "Appearance")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance", language: "zh-Hans"), "外观")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.system", language: "en"), "Follow System")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.system", language: "zh-Hans"), "跟随系统")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.day", language: "en"), "Day")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.day", language: "zh-Hans"), "日间")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.dark", language: "en"), "Dark")
        XCTAssertEqual(catalog.localizedValue(for: "personal.appearance.dark", language: "zh-Hans"), "深色")
        XCTAssertEqual(catalog.localizedValue(for: "review.delete.accessibility.label", language: "en"), "Delete %@")
        XCTAssertEqual(catalog.localizedValue(for: "review.delete.accessibility.label", language: "zh-Hans"), "删除 %@")
        XCTAssertEqual(catalog.localizedValue(for: "nav.review", language: "zh-Hans"), "复习")
        XCTAssertEqual(catalog.localizedValue(for: "nav.personal", language: "zh-Hans"), "个人")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.free", language: "en"), "Free")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.free", language: "zh-Hans"), "免费")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proMonthly", language: "en"), "Pro Monthly")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proMonthly", language: "zh-Hans"), "Pro 月度套餐")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proQuarterly", language: "en"), "Pro Quarterly")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proQuarterly", language: "zh-Hans"), "Pro 季度套餐")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proYearly", language: "en"), "Pro Yearly")
        XCTAssertEqual(catalog.localizedValue(for: "subscription.product.proYearly", language: "zh-Hans"), "Pro 年度套餐")
    }

    func testChineseLegalNoticePreservesRequiredAttributionAndLicenses() throws {
        let catalog = try loadStringCatalog()
        let legalNotice = try XCTUnwrap(
            catalog.localizedValue(for: "personal.sourcesAndLicenses.body", language: "zh-Hans")
        )

        XCTAssertTrue(legalNotice.contains("Creative Commons Attribution-ShareAlike 4.0 International"))
        XCTAssertTrue(legalNotice.contains("Copyright (c) James William Breen"))
        XCTAssertTrue(legalNotice.contains("Electronic Dictionary Research and Development Group"))
        XCTAssertTrue(legalNotice.contains("google/siglip-base-patch16-224"))
        XCTAssertTrue(legalNotice.contains("Apache License 2.0"))
    }

    func testLocalizableCatalogPassesSharedStructuralAudit() throws {
        let issues = try LocalizationCatalogValidator.issues(
            in: try Data(
                contentsOf: projectRoot()
                    .appendingPathComponent("JapCapture/Localizable.xcstrings")
            ),
            configuration: HibiLensLocalizationQAConfiguration.catalog
        )
        XCTAssertEqual(issues, [])
    }

    func testInfoPlistStringsContainLocalizedAppNameAndCameraPermission() throws {
        let englishInfo = try loadInfoPlistStrings(languageDirectory: "en.lproj")
        let chineseInfo = try loadInfoPlistStrings(languageDirectory: "zh-Hans.lproj")

        XCTAssertEqual(englishInfo["CFBundleDisplayName"], "Hibi Lens")
        XCTAssertEqual(chineseInfo["CFBundleDisplayName"], "日摄")
        XCTAssertEqual(
            englishInfo["NSCameraUsageDescription"],
            "Hibi Lens uses the camera to capture objects and Japanese text for study."
        )
        XCTAssertEqual(
            chineseInfo["NSCameraUsageDescription"],
            "日摄需要使用相机来拍摄物品和日语文字，帮助你学习。"
        )
    }

    func testProjectDeclaresSimplifiedChineseLocalizationRegion() throws {
        let projectText = try String(
            contentsOf: projectRoot().appendingPathComponent("JapCapture.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )
        let knownRegions = try projectListValues(named: "knownRegions", in: projectText)
        let debugConfiguration = try projectObjectBlock(
            id: "A0A8DBAC2F7AFD970045C314",
            comment: "Debug",
            in: projectText
        )
        let releaseConfiguration = try projectObjectBlock(
            id: "A0A8DBAD2F7AFD970045C314",
            comment: "Release",
            in: projectText
        )

        XCTAssertTrue(projectText.contains("developmentRegion = en;"))
        XCTAssertEqual(knownRegions, ["en", "Base", "zh-Hans"])
        XCTAssertTrue(
            debugConfiguration.contains(#"INFOPLIST_KEY_CFBundleDisplayName = "Hibi Lens";"#),
            "Debug app build configuration should declare CFBundleDisplayName"
        )
        XCTAssertTrue(
            releaseConfiguration.contains(#"INFOPLIST_KEY_CFBundleDisplayName = "Hibi Lens";"#),
            "Release app build configuration should declare CFBundleDisplayName"
        )
    }

    private func loadStringCatalog() throws -> StringCatalog {
        let data = try Data(contentsOf: projectRoot().appendingPathComponent("JapCapture/Localizable.xcstrings"))
        return try JSONDecoder().decode(StringCatalog.self, from: data)
    }

    private func loadInfoPlistStrings(languageDirectory: String) throws -> [String: String] {
        let url = projectRoot()
            .appendingPathComponent("JapCapture")
            .appendingPathComponent(languageDirectory)
            .appendingPathComponent("InfoPlist.strings")
        let data = try Data(contentsOf: url)
        var format = PropertyListSerialization.PropertyListFormat.openStep
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
        return try XCTUnwrap(plist as? [String: String], "\(languageDirectory)/InfoPlist.strings should be a string dictionary")
    }

    private func projectListValues(named listName: String, in projectText: String) throws -> [String] {
        let startToken = "\(listName) = ("
        let startRange = try XCTUnwrap(projectText.range(of: startToken), "Missing \(listName) list")
        let listStart = startRange.upperBound
        let listEnd = try XCTUnwrap(projectText[listStart...].range(of: ");")?.lowerBound, "Missing \(listName) list terminator")
        return projectText[listStart..<listEnd]
            .split(separator: "\n")
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\","))
            }
            .filter { !$0.isEmpty }
    }

    private func projectObjectBlock(id: String, comment: String, in projectText: String) throws -> String {
        let startToken = "\(id) /* \(comment) */ = {"
        let startRange = try XCTUnwrap(projectText.range(of: startToken), "Missing project object \(id) /* \(comment) */")
        let blockEnd = try XCTUnwrap(
            projectText[startRange.upperBound...].range(of: "\n\t\t};")?.upperBound,
            "Missing project object terminator for \(id) /* \(comment) */"
        )
        return String(projectText[startRange.lowerBound..<blockEnd])
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private extension LocalizationResourceTests.StringCatalog {
    func localizedValue(for key: String, language: String) -> String? {
        strings[key]?.localizations?[language]?.stringUnit.value
    }
}
