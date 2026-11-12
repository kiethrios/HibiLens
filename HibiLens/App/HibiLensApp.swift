import SwiftUI
import SwiftData

@main
struct HibiLensApp: App {
    init() {
        AppTabBarAppearance.apply()
    }

    @AppStorage(AppAppearancePreference.storageKey)
    private var appearanceRawValue = AppAppearancePreference.defaultValue.rawValue

    private let modelContainer: ModelContainer = {
        do {
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("-review-demo") {
                return try ReviewDemoData.makeContainer()
            }
            #endif
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
