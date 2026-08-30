//
//  AppStorageBootstrap.swift
//  JapCapture
//
//  Created by Codex on 2026/5/18.
//

import Foundation

enum AppStorageBootstrap {
    @discardableResult
    static func ensureApplicationSupportDirectoryExists(at applicationSupportURL: URL? = nil) throws -> URL {
        let directoryURL = applicationSupportURL ?? defaultApplicationSupportDirectoryURL()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    private static func defaultApplicationSupportDirectoryURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }
}
