import Foundation
import SwiftData

enum StudyProgressState: String, Codable, CaseIterable {
    case new
    case learned
    case mastered
}

@Model
final class StudyProgress {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) private(set) var cardID: UUID
    private var stateRawValue: String
    var markedLearnedAt: Date?
    var markedMasteredAt: Date?
    var lastTouchedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var state: StudyProgressState {
        get { StudyProgressState(rawValue: stateRawValue) ?? .new }
        set {
            stateRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    init(
        id: UUID = UUID(),
        cardID: UUID,
        state: StudyProgressState = .new,
        markedLearnedAt: Date? = nil,
        markedMasteredAt: Date? = nil,
        lastTouchedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.cardID = cardID
        self.stateRawValue = state.rawValue
        self.markedLearnedAt = markedLearnedAt
        self.markedMasteredAt = markedMasteredAt
        self.lastTouchedAt = lastTouchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func markLearned(at date: Date = .now) {
        if markedLearnedAt == nil {
            markedLearnedAt = date
        }

        markedMasteredAt = nil
        state = .learned
        lastTouchedAt = date
        updatedAt = date
    }

    func markMastered(at date: Date = .now) {
        if markedLearnedAt == nil {
            markedLearnedAt = date
        }

        markedMasteredAt = date
        state = .mastered
        lastTouchedAt = date
        updatedAt = date
    }
}
