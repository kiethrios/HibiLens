import UIKit

final class StoredImageMemoryCache {
    static let shared = StoredImageMemoryCache()

    private let cache: NSCache<NSString, UIImage>

    init(
        countLimit: Int = 300,
        totalCostLimit: Int = 60 * 1024 * 1024
    ) {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
        self.cache = cache
    }

    func image(for relativePath: String) -> UIImage? {
        cache.object(forKey: relativePath as NSString)
    }

    func store(_ image: UIImage, for relativePath: String) {
        cache.setObject(
            image,
            forKey: relativePath as NSString,
            cost: imageMemoryCost(image)
        )
    }

    func removeAllImages() {
        cache.removeAllObjects()
    }

    private func imageMemoryCost(_ image: UIImage) -> Int {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        return Int(pixelWidth * pixelHeight * 4)
    }
}
