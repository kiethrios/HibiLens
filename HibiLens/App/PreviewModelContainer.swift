import Foundation
import SwiftData

enum PreviewModelContainer {
    static let shared: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: VocabularyCard.self,
            StudyProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        let learningCard = VocabularyCard(
            capturedAt: .now.addingTimeInterval(-3_600),
            imageLocalPath: "",
            japaneseText: "猫",
            kanaText: "ねこ",
            kanjiText: "猫",
            romajiText: "Neko",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        learningCard.studyProgress = StudyProgress(
            cardID: learningCard.id,
            state: .learned,
            markedLearnedAt: .now.addingTimeInterval(-3_600),
            lastTouchedAt: .now.addingTimeInterval(-3_600)
        )

        let masteredCard = VocabularyCard(
            capturedAt: .now.addingTimeInterval(-7_200),
            imageLocalPath: "",
            japaneseText: "山",
            kanaText: "やま",
            kanjiText: "山",
            romajiText: "Yama",
            translationEnglish: "Mountain",
            translationChinese: "山"
        )
        masteredCard.studyProgress = StudyProgress(
            cardID: masteredCard.id,
            state: .mastered,
            markedLearnedAt: .now.addingTimeInterval(-86_400),
            markedMasteredAt: .now.addingTimeInterval(-1_800),
            lastTouchedAt: .now.addingTimeInterval(-1_800)
        )

        let cards = [learningCard, masteredCard]

        cards.forEach(context.insert)
        try? context.save()
        return container
    }()
}
