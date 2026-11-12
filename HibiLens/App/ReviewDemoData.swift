#if DEBUG && targetEnvironment(simulator)
import SwiftData
import UIKit

/// Disposable, opt-in simulator data for inspecting review layouts.
enum ReviewDemoData {
    static func makeContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: VocabularyCard.self, StudyProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let entries: [(String, String, String, String, String, String)] = [
            ("猫", "ねこ", "neko", "Cat", "猫", "cat.fill"),
            ("本", "ほん", "hon", "Book", "书", "book.closed.fill"),
            ("自転車", "じてんしゃ", "jitensha", "Bicycle", "自行车", "bicycle"),
            ("コーヒーカップ", "こーひーかっぷ", "kōhī kappu", "Coffee cup", "咖啡杯", "cup.and.saucer.fill"),
            ("傘", "かさ", "kasa", "Umbrella", "雨伞", "umbrella.fill"),
            ("時計", "とけい", "tokei", "Clock", "时钟", "clock.fill"),
            ("眼鏡", "めがね", "megane", "Glasses", "眼镜", "eyeglasses"),
            ("ヘッドフォン", "へっどふぉん", "heddofon", "Headphones", "耳机", "headphones"),
            ("葉", "は", "ha", "Leaf", "叶子", "leaf.fill"),
            ("椅子", "いす", "isu", "Chair", "椅子", "chair.fill"),
            ("バックパック", "ばっくぱっく", "bakkupakku", "Backpack", "背包", "backpack.fill"),
            ("スニーカー", "すにーかー", "sunīkā", "Sneakers", "运动鞋", "shoe.fill"),
            ("山", "やま", "yama", "Mountain", "山", "mountain.2.fill"),
            ("花", "はな", "hana", "Flower", "花", "camera.macro"),
            ("車", "くるま", "kuruma", "Car", "汽车", "car.fill"),
            ("飛行機", "ひこうき", "hikōki", "Airplane", "飞机", "airplane")
        ]
        let context = container.mainContext
        for (index, entry) in entries.enumerated() {
            let path = try imagePath(symbol: entry.5)
            let card = VocabularyCard(
                capturedAt: .now.addingTimeInterval(-Double(index) * 3600),
                imageLocalPath: path,
                japaneseText: entry.0, kanaText: entry.1, romajiText: entry.2,
                translationEnglish: entry.3, translationChinese: entry.4
            )
            card.studyProgress = StudyProgress(
                cardID: card.id, state: index < 12 ? .learned : .mastered,
                markedLearnedAt: .now,
                markedMasteredAt: index < 12 ? nil : .now
            )
            context.insert(card)
        }
        try context.save()
        return container
    }

    private static func imagePath(symbol: String) throws -> String {
        let storage = LocalImageStorage.shared
        let path = "review-demo/" + symbol + ".png"
        let url = storage.url(for: path)
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let image = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 320)).image { _ in
                let icon = UIImage(
                    systemName: symbol,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 130, weight: .regular)
                )?.withTintColor(UIColor(red: 0.23, green: 0.43, blue: 0.37, alpha: 1),
                                 renderingMode: .alwaysOriginal)
                if let icon {
                    let scale = min(230 / icon.size.width, 210 / icon.size.height)
                    let size = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
                    icon.draw(in: CGRect(x: (320 - size.width) / 2, y: (320 - size.height) / 2,
                                         width: size.width, height: size.height))
                }
            }
            if let data = image.pngData() {
                try data.write(to: url, options: .atomic)
            }
        }
        return path
    }
}
#endif
