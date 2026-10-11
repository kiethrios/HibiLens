import Foundation
import UIKit

struct CardImageAssets: Equatable {
    let fullImagePath: String
    let thumbnailImagePath: String
    let aspectRatio: Double
}

struct CardImageAssetGenerator {
    private let storage: LocalImageStorage
    private let thumbnailMaxPixelLength: CGFloat

    init(
        storage: LocalImageStorage = .shared,
        thumbnailMaxPixelLength: CGFloat = 640
    ) {
        self.storage = storage
        self.thumbnailMaxPixelLength = thumbnailMaxPixelLength
    }

    func makeAssets(
        originalData: Data,
        previewImage: UIImage
    ) throws -> CardImageAssets {
        let fullImagePath = try storage.saveProcessedImageData(originalData)

        do {
            let thumbnail = Self.thumbnail(
                from: previewImage,
                maxPixelLength: thumbnailMaxPixelLength
            )
            guard let thumbnailData = thumbnail.pngData() else {
                throw CardImageAssetGeneratorError.thumbnailEncodingFailed
            }

            let thumbnailImagePath = try storage.saveThumbnailImageData(thumbnailData)
            return CardImageAssets(
                fullImagePath: fullImagePath,
                thumbnailImagePath: thumbnailImagePath,
                aspectRatio: Self.aspectRatio(for: previewImage)
            )
        } catch {
            try? storage.removeImage(at: fullImagePath)
            throw error
        }
    }

    private static func thumbnail(
        from image: UIImage,
        maxPixelLength: CGFloat
    ) -> UIImage {
        guard maxPixelLength > 0 else { return image }

        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxPixelLength else { return image }

        let scale = maxPixelLength / longestSide
        let thumbnailSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: thumbnailSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
    }

    private static func aspectRatio(for image: UIImage) -> Double {
        guard image.size.height > 0 else { return 1 }
        return Double(image.size.width / image.size.height)
    }
}

enum CardImageAssetGeneratorError: Error {
    case thumbnailEncodingFailed
}
