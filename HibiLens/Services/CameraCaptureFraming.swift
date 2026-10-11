import UIKit

enum CameraCaptureFraming {
    /// The rect uses normalized, unrotated camera metadata coordinates and is mapped through
    /// `image.imageOrientation` exactly once before cropping the upright image.
    nonisolated static func crop(_ image: UIImage, to normalizedVisibleRect: CGRect?) -> UIImage {
        let uprightImage = CaptureImageOrientationNormalizer.normalizeForSubjectLift(image)
        guard let normalizedVisibleRect,
              let cgImage = uprightImage.cgImage,
              [normalizedVisibleRect.origin.x, normalizedVisibleRect.origin.y,
               normalizedVisibleRect.width, normalizedVisibleRect.height].allSatisfy(\.isFinite)
        else {
            return uprightImage
        }

        let rawRect = normalizedVisibleRect.standardized
        let transformedRect = uprightRect(for: rawRect, orientation: image.imageOrientation)
        guard [transformedRect.origin.x, transformedRect.origin.y,
               transformedRect.width, transformedRect.height].allSatisfy(\.isFinite)
        else {
            return uprightImage
        }

        let unitBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
        let visibleRect = transformedRect.standardized.intersection(unitBounds)
        guard !visibleRect.isNull, !visibleRect.isEmpty else { return uprightImage }

        let pixelBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let minX = pixelEdge(visibleRect.minX, dimension: pixelBounds.width)
        let minY = pixelEdge(visibleRect.minY, dimension: pixelBounds.height)
        let maxX = pixelEdge(visibleRect.maxX, dimension: pixelBounds.width)
        let maxY = pixelEdge(visibleRect.maxY, dimension: pixelBounds.height)
        let requestedPixels = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
        let cropPixels = requestedPixels.integral.intersection(pixelBounds)
        guard !cropPixels.isNull, !cropPixels.isEmpty,
              let croppedImage = cgImage.cropping(to: cropPixels)
        else {
            return uprightImage
        }

        return UIImage(cgImage: croppedImage, scale: uprightImage.scale, orientation: .up)
    }

    nonisolated private static func pixelEdge(_ normalizedEdge: CGFloat, dimension: CGFloat) -> CGFloat {
        let pixel = normalizedEdge * dimension
        let roundedPixel = pixel.rounded()
        return abs(pixel - roundedPixel) < 1e-8 ? roundedPixel : pixel
    }

    nonisolated private static func uprightRect(for rawRect: CGRect, orientation: UIImage.Orientation) -> CGRect {
        switch orientation {
        case .up:
            return rawRect
        case .upMirrored:
            return CGRect(x: 1 - rawRect.maxX, y: rawRect.minY, width: rawRect.width, height: rawRect.height)
        case .down:
            return CGRect(x: 1 - rawRect.maxX, y: 1 - rawRect.maxY, width: rawRect.width, height: rawRect.height)
        case .downMirrored:
            return CGRect(x: rawRect.minX, y: 1 - rawRect.maxY, width: rawRect.width, height: rawRect.height)
        case .left:
            return CGRect(x: rawRect.minY, y: 1 - rawRect.maxX, width: rawRect.height, height: rawRect.width)
        case .leftMirrored:
            return CGRect(x: rawRect.minY, y: rawRect.minX, width: rawRect.height, height: rawRect.width)
        case .right:
            return CGRect(x: 1 - rawRect.maxY, y: rawRect.minX, width: rawRect.height, height: rawRect.width)
        case .rightMirrored:
            return CGRect(x: 1 - rawRect.maxY, y: 1 - rawRect.maxX, width: rawRect.height, height: rawRect.width)
        @unknown default:
            return rawRect
        }
    }
}
