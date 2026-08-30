import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

final class AppIconAssetTests: XCTestCase {
    private struct Catalog: Decodable {
        struct Image: Decodable {
            struct Appearance: Decodable {
                let appearance: String
                let value: String
            }

            let appearances: [Appearance]?
            let filename: String?
            let idiom: String
            let platform: String
            let size: String
        }

        let images: [Image]
    }

    private let expectedFilenames: [String: String] = [
        "default": "AppIcon-Default.png",
        "dark": "AppIcon-Dark.png",
        "tinted": "AppIcon-Tinted.png",
    ]

    func testCatalogReferencesEveryRequiredAppearance() throws {
        let catalog = try loadCatalog()
        let actual = Dictionary(uniqueKeysWithValues: catalog.images.map { image in
            let appearance = image.appearances?.first?.value ?? "default"
            return (appearance, image.filename)
        })

        XCTAssertEqual(catalog.images.count, 3)
        XCTAssertEqual(actual["default"]!, expectedFilenames["default"])
        XCTAssertEqual(actual["dark"]!, expectedFilenames["dark"])
        XCTAssertEqual(actual["tinted"]!, expectedFilenames["tinted"])

        for image in catalog.images {
            XCTAssertEqual(image.idiom, "universal")
            XCTAssertEqual(image.platform, "ios")
            XCTAssertEqual(image.size, "1024x1024")
        }
    }

    func testAppIconPNGsAreOpaque1024PixelImages() throws {
        for filename in expectedFilenames.values {
            let url = appIconDirectory().appendingPathComponent(filename)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil), filename)
            let properties = try XCTUnwrap(
                CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                filename
            )

            XCTAssertEqual(CGImageSourceGetType(source), UTType.png.identifier as CFString, filename)
            XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 1024, filename)
            XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 1024, filename)
            XCTAssertNotEqual(properties[kCGImagePropertyHasAlpha] as? Bool, true, filename)
        }
    }

    private func loadCatalog() throws -> Catalog {
        let data = try Data(contentsOf: appIconDirectory().appendingPathComponent("Contents.json"))
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    private func appIconDirectory() -> URL {
        projectRoot().appendingPathComponent("JapCapture/Assets.xcassets/AppIcon.appiconset")
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
