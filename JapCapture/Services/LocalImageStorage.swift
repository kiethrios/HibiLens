//
//  LocalImageStorage.swift
//  JapCapture
//
//  Created by Codex on 2026/4/17.
//

import Foundation
import UIKit

struct LocalImageStorage {
    nonisolated static let shared = LocalImageStorage()

    nonisolated let rootURL: URL

    nonisolated init(
        rootURL: URL? = nil
    ) {
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.rootURL = baseURL.appendingPathComponent("JapCaptureStorage", isDirectory: true)
        }
    }

    nonisolated func saveProcessedImageData(_ data: Data, fileExtension: String = "png") throws -> String {
        try ensureBaseDirectories()

        let sanitizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let relativePath = "processed-images/\(UUID().uuidString).\(sanitizedExtension)"
        let destinationURL = url(for: relativePath)

        try data.write(to: destinationURL, options: .atomic)
        return relativePath
    }

    nonisolated func saveThumbnailImageData(_ data: Data, fileExtension: String = "png") throws -> String {
        try ensureBaseDirectories()

        let sanitizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let relativePath = "processed-thumbnails/\(UUID().uuidString).\(sanitizedExtension)"
        let destinationURL = url(for: relativePath)

        try data.write(to: destinationURL, options: .atomic)
        return relativePath
    }

    nonisolated func loadImageData(at relativePath: String) throws -> Data {
        try Data(contentsOf: url(for: relativePath))
    }

    nonisolated func loadImage(at relativePath: String) throws -> UIImage {
        let data = try loadImageData(at: relativePath)
        guard let image = UIImage(data: data) else {
            throw LocalImageStorageError.invalidImageData
        }
        return image
    }

    nonisolated func removeImage(at relativePath: String) throws {
        let imageURL = url(for: relativePath)
        guard FileManager.default.fileExists(atPath: imageURL.path) else { return }
        try FileManager.default.removeItem(at: imageURL)
    }

    nonisolated func url(for relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    nonisolated private func ensureBaseDirectories() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: rootURL.appendingPathComponent("processed-images", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: rootURL.appendingPathComponent("processed-thumbnails", isDirectory: true),
            withIntermediateDirectories: true
        )
    }
}

enum LocalImageStorageError: Error {
    case invalidImageData
}
