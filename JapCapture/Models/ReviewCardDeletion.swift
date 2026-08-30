//
//  ReviewCardDeletion.swift
//  JapCapture
//
//  Created by Codex on 2026/5/20.
//

import SwiftData

enum ReviewCardDeletion {
    static func delete(_ card: VocabularyCard, in modelContext: ModelContext) {
        modelContext.delete(card)
    }
}
