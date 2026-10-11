import UIKit
import XCTest
@testable import HibiLens

final class CameraCaptureFramingTests: XCTestCase {
    func testCenterCropUsesNormalizedPortraitPixelBounds() throws {
        let image = makeImage(size: CGSize(width: 100, height: 200))

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 50)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
        XCTAssertEqual(cropped.imageOrientation, .up)
    }

    func testLandscapeCropUsesNormalizedHorizontalBounds() throws {
        let image = makeImage(size: CGSize(width: 240, height: 120))

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0.125, y: 0, width: 0.75, height: 1))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 180)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 120)
    }

    func testNilRectReturnsFullNormalizedImage() throws {
        let image = makeImage(size: CGSize(width: 100, height: 200), scale: 2)

        let result = CameraCaptureFraming.crop(image, to: nil)

        XCTAssertEqual(try XCTUnwrap(result.cgImage).width, 200)
        XCTAssertEqual(try XCTUnwrap(result.cgImage).height, 400)
        XCTAssertEqual(result.scale, 2)
        XCTAssertEqual(result.imageOrientation, .up)
    }

    func testInvalidAndNonintersectingRectsReturnFullImage() throws {
        let image = makeImage(size: CGSize(width: 100, height: 200))
        let rects = [
            CGRect(x: .nan, y: 0, width: 0.5, height: 0.5),
            CGRect(x: 0, y: .infinity, width: 0.5, height: 0.5),
            CGRect(x: 0.25, y: 0.25, width: 0, height: 0.5),
            CGRect(x: 1.5, y: 0, width: 0.2, height: 1)
        ]

        for rect in rects {
            let result = CameraCaptureFraming.crop(image, to: rect)
            XCTAssertEqual(try XCTUnwrap(result.cgImage).width, 100, "rect: \(rect)")
            XCTAssertEqual(try XCTUnwrap(result.cgImage).height, 200, "rect: \(rect)")
        }
    }

    func testNegativeSizeRectIsStandardizedAndClippedToImageBounds() throws {
        let image = makeImage(size: CGSize(width: 100, height: 200))

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0.5, y: 0.75, width: -0.75, height: -0.5))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 50)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
    }

    func testFractionalCropRoundsOutwardAndClipsAtImageBounds() throws {
        let image = makeImage(size: CGSize(width: 100, height: 200))

        // Pixel-space edges after clipping: x 12.5...87.7, y 43.4...200.
        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0.125, y: 0.217, width: 0.752, height: 0.819))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 76) // Pixel columns 12...87.
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 157) // Pixel rows 43...199.
    }

    func testNormalizedCoordinatesSelectExpectedQuadrants() throws {
        let image = makeQuadrantImage()

        let topLeft = CameraCaptureFraming.crop(image, to: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        let topRight = CameraCaptureFraming.crop(image, to: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5))
        let bottomLeft = CameraCaptureFraming.crop(image, to: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5))
        let bottomRight = CameraCaptureFraming.crop(image, to: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))

        XCTAssertEqual(try pixelRGBA(of: topLeft), [255, 0, 0, 255])
        XCTAssertEqual(try pixelRGBA(of: topRight), [0, 0, 255, 255])
        XCTAssertEqual(try pixelRGBA(of: bottomLeft), [0, 255, 0, 255])
        XCTAssertEqual(try pixelRGBA(of: bottomRight), [255, 255, 0, 255])
    }

    func testNonUprightImageNormalizesBeforeCropAndPreservesScale() throws {
        let upright = makeImage(size: CGSize(width: 100, height: 200), scale: 2)
        let rotated = UIImage(cgImage: try XCTUnwrap(upright.cgImage), scale: 2, orientation: .right)

        let cropped = CameraCaptureFraming.crop(rotated, to: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        XCTAssertEqual(cropped.imageOrientation, .up)
        XCTAssertEqual(cropped.scale, 2)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 200)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
    }

    func testRightOrientationRotatesMetadataRectBeforeCroppingVisibleBand() throws {
        let source = makeHorizontalBandImage()
        let image = UIImage(cgImage: try XCTUnwrap(source.cgImage), scale: 1, orientation: .right)

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0, y: 0.2, width: 1, height: 0.6))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 120)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
        XCTAssertEqual(try pixelRGBA(of: cropped, atX: 0.05), [0, 255, 0, 255])
        XCTAssertEqual(try pixelRGBA(of: cropped, atX: 0.95), [0, 255, 0, 255])
    }

    func testLeftOrientationRotatesMetadataRectBeforeCroppingVisibleBand() throws {
        let source = makeHorizontalBandImage()
        let image = UIImage(cgImage: try XCTUnwrap(source.cgImage), scale: 1, orientation: .left)

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0, y: 0.2, width: 1, height: 0.6))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 120)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
        XCTAssertEqual(try pixelRGBA(of: cropped, atX: 0.05), [0, 255, 0, 255])
        XCTAssertEqual(try pixelRGBA(of: cropped, atX: 0.95), [0, 255, 0, 255])
    }

    func testQuarterTurnOrientationsMapRawTopLeftToTheirDistinctUprightCorners() throws {
        let source = makeQuadrantImage()
        let cgImage = try XCTUnwrap(source.cgImage)
        let rawTopLeft = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)

        for orientation: UIImage.Orientation in [.right, .left] {
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
            let cropped = CameraCaptureFraming.crop(image, to: rawTopLeft)

            XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 100, "orientation: \(orientation.rawValue)")
            XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 50, "orientation: \(orientation.rawValue)")
            XCTAssertEqual(try pixelRGBA(of: cropped), [255, 0, 0, 255], "orientation: \(orientation.rawValue)")
        }
    }

    func testDownOrientationMapsRawTopLeftToUprightBottomRight() throws {
        let source = makeQuadrantImage()
        let image = UIImage(cgImage: try XCTUnwrap(source.cgImage), scale: 1, orientation: .down)

        let cropped = CameraCaptureFraming.crop(image, to: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).width, 50)
        XCTAssertEqual(try XCTUnwrap(cropped.cgImage).height, 100)
        XCTAssertEqual(try pixelRGBA(of: cropped), [255, 0, 0, 255])
    }

    func testMirroredOrientationsMapRawQuadrantsToUprightPixels() throws {
        let source = makeQuadrantImage()
        let cgImage = try XCTUnwrap(source.cgImage)
        let cases: [(UIImage.Orientation, CGRect, [UInt8])] = [
            (.upMirrored, CGRect(x: 0, y: 0, width: 0.5, height: 0.5), [255, 0, 0, 255]),
            (.downMirrored, CGRect(x: 0, y: 0, width: 0.5, height: 0.5), [255, 0, 0, 255]),
            (.leftMirrored, CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5), [0, 0, 255, 255]),
            (.rightMirrored, CGRect(x: 0, y: 0, width: 0.5, height: 0.5), [255, 0, 0, 255])
        ]

        for (orientation, rawRect, expectedColor) in cases {
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
            let cropped = CameraCaptureFraming.crop(image, to: rawRect)

            XCTAssertEqual(try pixelRGBA(of: cropped), expectedColor, "orientation: \(orientation.rawValue)")
        }
    }

    private func makeImage(size: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeQuadrantImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 50, height: 100))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 50, y: 0, width: 50, height: 100))
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 100, width: 50, height: 100))
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 50, y: 100, width: 50, height: 100))
        }
    }

    private func makeHorizontalBandImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 40))
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 40, width: 100, height: 120))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 160, width: 100, height: 40))
        }
    }

    private func pixelRGBA(of image: UIImage, atX xFraction: CGFloat = 0.5, atY yFraction: CGFloat = 0.5) throws -> [UInt8] {
        let cgImage = try XCTUnwrap(image.cgImage)
        let x = min(max(Int(xFraction * CGFloat(cgImage.width)), 0), cgImage.width - 1)
        let y = min(max(Int(yFraction * CGFloat(cgImage.height)), 0), cgImage.height - 1)
        let pixel = try XCTUnwrap(cgImage.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)))
        var bytes = [UInt8](repeating: 0, count: 4)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let context = try XCTUnwrap(CGContext(
            data: &bytes,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ))
        context.interpolationQuality = .none
        context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return bytes
    }
}
