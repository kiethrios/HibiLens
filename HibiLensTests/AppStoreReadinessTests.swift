import Foundation
import XCTest

final class AppStoreReadinessTests: XCTestCase {
    func testPrivacyManifestDeclaresLocalUserDefaultsReasonAndNoTracking() throws {
        let manifest = try loadPrivacyManifest()
        let accessedAPITypes = try XCTUnwrap(
            manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]]
        )
        let userDefaultsDeclaration = try XCTUnwrap(
            accessedAPITypes.first {
                $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
            }
        )
        let reasons = try XCTUnwrap(
            userDefaultsDeclaration["NSPrivacyAccessedAPITypeReasons"] as? [String]
        )

        XCTAssertEqual(reasons, ["CA92.1"])
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertTrue((manifest["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)
        XCTAssertTrue((manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])?.isEmpty == true)
    }

    func testAppBundleIncludesPrivacyManifestButNotRepoOnlyDesignNotes() {
        XCTAssertNotNil(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        XCTAssertNil(Bundle.main.url(forResource: "DESIGN", withExtension: "md"))
    }

    private func loadPrivacyManifest() throws -> [String: Any] {
        let url = projectRoot().appendingPathComponent("HibiLens/PrivacyInfo.xcprivacy")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
