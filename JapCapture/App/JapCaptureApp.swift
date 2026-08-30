//
//  JapCaptureApp.swift
//  JapCapture
//
//  Created by kiethrios on 2026/3/31.
//

import SwiftUI
import SwiftData

@main
struct JapCaptureApp: App {
    @AppStorage(AppAppearancePreference.storageKey)
    private var appearanceRawValue = AppAppearancePreference.defaultValue.rawValue

    private let modelContainer: ModelContainer = {
        do {
            try AppStorageBootstrap.ensureApplicationSupportDirectoryExists()
            return try ModelContainer(for: VocabularyCard.self, StudyProgress.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()

    private var appearancePreference: AppAppearancePreference {
        AppAppearancePreference.resolve(rawValue: appearanceRawValue)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearancePreference.preferredColorScheme)
        }
        .modelContainer(modelContainer)
    }
}
