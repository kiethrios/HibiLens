import Foundation
import UIKit

struct LabelScore: Equatable {
    let label: String
    let score: Float
}

protocol LocalImageLabelClassifier {
    var displayName: String { get }

    func prewarm() async throws
    func classify(image: UIImage, topK: Int) async throws -> [LabelScore]
}

extension LocalImageLabelClassifier {
    var displayName: String {
        String(describing: type(of: self))
    }

    func prewarm() async throws {}
}

enum LocalImageLabelLogMessage {
    static let maximumLabelCount = 5

    static func make(
        backendName: String = "SigLIPImageLabelClassifier",
        scores: [LabelScore]
    ) -> String {
        let topScores = scores.prefix(maximumLabelCount)
        let labelText = topScores.isEmpty
            ? "(none)"
            : topScores
                .map { "\($0.label):\(String(format: "%.3f", $0.score))" }
                .joined(separator: ", ")
        return "[\(backendName)] labels=\(labelText)"
    }
}

enum ImageTextSimilarity {
    static func cosineSimilarity(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

        let dotProduct = zip(lhs, rhs).reduce(Float.zero) { $0 + $1.0 * $1.1 }
        let lhsMagnitude = sqrt(lhs.reduce(Float.zero) { $0 + $1 * $1 })
        let rhsMagnitude = sqrt(rhs.reduce(Float.zero) { $0 + $1 * $1 })
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }

        return dotProduct / (lhsMagnitude * rhsMagnitude)
    }

    static func normalized(_ embedding: [Float]) -> [Float] {
        let magnitude = sqrt(embedding.reduce(Float.zero) { $0 + $1 * $1 })
        guard magnitude > 0 else { return embedding }
        return embedding.map { $0 / magnitude }
    }

    static func dotProduct(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
        return zip(lhs, rhs).reduce(Float.zero) { $0 + $1.0 * $1.1 }
    }
}
