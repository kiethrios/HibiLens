import CoreImage
import CoreML
import Foundation
import UIKit

extension MLMultiArray {
    nonisolated func floatArray() -> [Float] {
        if dataType == .float32 {
            return withUnsafeBufferPointer(ofType: Float.self) { pointer in
                Array(pointer)
            }
        }

        return (0..<count).map { index in
            self[index].floatValue
        }
    }
}

extension CIImage {
    nonisolated func cropToSquare() -> CIImage? {
        let size = min(extent.width, extent.height)
        let x = round((extent.width - size) / 2)
        let y = round((extent.height - size) / 2)

        return cropped(to: CGRect(x: x, y: y, width: size, height: size))
            .transformed(by: CGAffineTransform(translationX: -x, y: -y))
    }

    nonisolated func resize(size: CGSize) -> CIImage? {
        let scaleX = size.width / extent.width
        let scaleY = size.height / extent.height
        return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

extension UIImage.Orientation {
    nonisolated var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up:
            .up
        case .down:
            .down
        case .left:
            .left
        case .right:
            .right
        case .upMirrored:
            .upMirrored
        case .downMirrored:
            .downMirrored
        case .leftMirrored:
            .leftMirrored
        case .rightMirrored:
            .rightMirrored
        @unknown default:
            .up
        }
    }
}
