//
//  StoredImageView.swift
//  JapCapture
//
//  Created by Codex on 2026/4/17.
//

import SwiftUI
import UIKit

enum StoredImageContentMode: Equatable {
    case fit
    case fill

    static let `default`: StoredImageContentMode = .fit

    var swiftUIContentMode: ContentMode {
        switch self {
        case .fit:
            .fit
        case .fill:
            .fill
        }
    }
}

struct StoredImageView<Placeholder: View>: View {
    let relativePath: String?
    let contentMode: StoredImageContentMode
    let preservesLoadedAspectRatio: Bool
    let fallbackAspectRatio: CGFloat
    @ViewBuilder let placeholder: Placeholder

    @State private var image: UIImage?

    init(
        relativePath: String?,
        contentMode: StoredImageContentMode = .default,
        preservesLoadedAspectRatio: Bool = false,
        fallbackAspectRatio: CGFloat = 1,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.relativePath = relativePath
        self.contentMode = contentMode
        self.preservesLoadedAspectRatio = preservesLoadedAspectRatio
        self.fallbackAspectRatio = fallbackAspectRatio
        self.placeholder = placeholder()
    }

    var body: some View {
        ZStack {
            placeholder

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode.swiftUIContentMode)
            }
        }
        .aspectRatio(storedAspectRatio, contentMode: .fit)
        .frame(
            maxWidth: .infinity,
            maxHeight: preservesLoadedAspectRatio ? nil : .infinity
        )
        .task(id: relativePath) {
            await loadImage()
        }
    }

    private var storedAspectRatio: CGFloat? {
        guard preservesLoadedAspectRatio else { return nil }

        if let image, image.size.height > 0 {
            return image.size.width / image.size.height
        }

        return fallbackAspectRatio
    }

    private func loadImage() async {
        guard let relativePath else {
            image = nil
            return
        }

        do {
            image = try await StoredImageLoader.loadImage(at: relativePath)
        } catch {
            image = nil
        }
    }
}

struct ProgressiveStoredImageView<Placeholder: View>: View {
    let previewRelativePath: String?
    let fullRelativePath: String?
    let contentMode: StoredImageContentMode
    let preservesLoadedAspectRatio: Bool
    let fallbackAspectRatio: CGFloat
    @ViewBuilder let placeholder: Placeholder

    @State private var previewImage: UIImage?
    @State private var fullImage: UIImage?

    init(
        previewRelativePath: String?,
        fullRelativePath: String?,
        contentMode: StoredImageContentMode = .default,
        preservesLoadedAspectRatio: Bool = false,
        fallbackAspectRatio: CGFloat = 1,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.previewRelativePath = previewRelativePath
        self.fullRelativePath = fullRelativePath
        self.contentMode = contentMode
        self.preservesLoadedAspectRatio = preservesLoadedAspectRatio
        self.fallbackAspectRatio = fallbackAspectRatio
        self.placeholder = placeholder()
        _previewImage = State(
            initialValue: previewRelativePath.flatMap {
                StoredImageLoader.cachedImage(at: $0)
            }
        )
        _fullImage = State(
            initialValue: fullRelativePath.flatMap {
                StoredImageLoader.cachedImage(at: $0)
            }
        )
    }

    var body: some View {
        ZStack {
            placeholder

            if let previewImage {
                renderedImage(previewImage)
            }

            if let fullImage {
                renderedImage(fullImage)
            }
        }
        .aspectRatio(storedAspectRatio, contentMode: .fit)
        .frame(
            maxWidth: .infinity,
            maxHeight: preservesLoadedAspectRatio ? nil : .infinity
        )
        .task(id: "\(previewRelativePath ?? "nil")|\(fullRelativePath ?? "nil")") {
            await loadImages()
        }
    }

    private var storedAspectRatio: CGFloat? {
        guard preservesLoadedAspectRatio else { return nil }

        let image = fullImage ?? previewImage
        if let image, image.size.height > 0 {
            return image.size.width / image.size.height
        }

        return fallbackAspectRatio
    }

    private func renderedImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode.swiftUIContentMode)
    }

    private func loadImages() async {
        previewImage = previewRelativePath.flatMap {
            StoredImageLoader.cachedImage(at: $0)
        }
        fullImage = fullRelativePath.flatMap {
            StoredImageLoader.cachedImage(at: $0)
        }

        if let previewRelativePath {
            do {
                previewImage = try await StoredImageLoader.loadImage(at: previewRelativePath)
            } catch {
                previewImage = nil
            }
        }

        guard let fullRelativePath else { return }

        do {
            let loadedFullImage = try await StoredImageLoader.loadImage(at: fullRelativePath)
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                fullImage = loadedFullImage
            }
        } catch {
            fullImage = nil
        }
    }
}

enum StoredImageLoader {
    static func cachedImage(
        at relativePath: String,
        in cache: StoredImageMemoryCache = .shared
    ) -> UIImage? {
        cache.image(for: relativePath)
    }

    static func loadImage(at relativePath: String) async throws -> UIImage {
        if let cachedImage = cachedImage(at: relativePath) {
            CapturePerformanceLog.mark("stored_image.cache_hit.\(performanceLabel(for: relativePath))")
            return cachedImage
        }

        let loadedImage = try await CapturePerformanceLog.measureAsync(
            "stored_image.load.\(performanceLabel(for: relativePath))"
        ) {
            try await Task.detached {
                try LocalImageStorage.shared.loadImage(at: relativePath)
            }.value
        }
        if shouldCache(relativePath: relativePath) {
            StoredImageMemoryCache.shared.store(loadedImage, for: relativePath)
        }
        return loadedImage
    }

    static func performanceLabel(for relativePath: String) -> String {
        if relativePath.hasPrefix("processed-thumbnails/") {
            return "thumbnail"
        }
        if relativePath.hasPrefix("processed-images/") {
            return "full"
        }
        return "unknown"
    }

    static func shouldCache(relativePath: String) -> Bool {
        relativePath.hasPrefix("processed-thumbnails/")
    }
}
