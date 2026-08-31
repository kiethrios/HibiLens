import UIKit

enum CaptureImageOrientationNormalizer {
    nonisolated static func normalizeForSubjectLift(_ image: UIImage) -> UIImage {
        image.normalizedUprightImage()
    }

    nonisolated static func normalizeForCard(_ image: UIImage, rotationAngle: CGFloat?) -> UIImage {
        image.normalizedUprightImage().rotatedForCard(by: rotationAngle)
    }
}

private extension UIImage {
    nonisolated func normalizedUprightImage() -> UIImage {
        guard imageOrientation != .up || cgImage == nil else { return self }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    nonisolated func rotatedForCard(by rotationAngle: CGFloat?) -> UIImage {
        guard let rotationAngle else { return self }

        let normalizedAngle = rotationAngle.truncatingRemainder(dividingBy: 360)
        guard abs(normalizedAngle) > 0.001 else { return self }

        let radians = normalizedAngle * .pi / 180
        let rotatedRect = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
        let rotatedSize = CGSize(
            width: abs(rotatedRect.width),
            height: abs(rotatedRect.height)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: rotatedSize, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cgContext.rotate(by: radians)
            draw(
                in: CGRect(
                    x: -size.width / 2,
                    y: -size.height / 2,
                    width: size.width,
                    height: size.height
                )
            )
        }
    }
}
