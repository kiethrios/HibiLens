import SwiftData

enum ReviewCardDeletion {
    static func delete(_ card: VocabularyCard, in modelContext: ModelContext) {
        modelContext.delete(card)
    }
}
