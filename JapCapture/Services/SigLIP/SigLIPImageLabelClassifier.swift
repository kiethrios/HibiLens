import UIKit

protocol SigLIPImageEmbeddingProviding {
    nonisolated func prewarm() async throws
    nonisolated func imageEmbedding(for image: UIImage) async throws -> [Float]
}

extension SigLIPImageEmbeddingProviding {
    nonisolated func prewarm() async throws {}
}

enum SharedImageLabelClassifier {
    static let capture = SigLIPImageLabelClassifier()
}

final class SigLIPImageLabelClassifier: LocalImageLabelClassifier {
    private struct CandidateEmbedding {
        let label: String
        let embedding: [Float]
    }

    private let textEmbeddingStoreLoader: () throws -> SigLIPTextEmbeddingStore
    private let imageEmbeddingProvider: SigLIPImageEmbeddingProviding
    private let candidateEmbeddingsLock = NSLock()
    private var cachedCandidateEmbeddings: [CandidateEmbedding]?

    var displayName: String {
        "SigLIPImageLabelClassifier"
    }

    init(
        textEmbeddingStore: SigLIPTextEmbeddingStore,
        imageEmbeddingProvider: SigLIPImageEmbeddingProviding
    ) {
        textEmbeddingStoreLoader = { textEmbeddingStore }
        self.imageEmbeddingProvider = imageEmbeddingProvider
    }

    init(
        textEmbeddingStoreLoader: @escaping () throws -> SigLIPTextEmbeddingStore = {
            try SigLIPTextEmbeddingStore.loadFromBundle()
        },
        imageEmbeddingProvider: SigLIPImageEmbeddingProviding = CoreMLSigLIPImageEmbeddingProvider.shared
    ) {
        self.textEmbeddingStoreLoader = textEmbeddingStoreLoader
        self.imageEmbeddingProvider = imageEmbeddingProvider
    }

    convenience init() {
        self.init(
            textEmbeddingStoreLoader: { try SigLIPTextEmbeddingStore.loadFromBundle() },
            imageEmbeddingProvider: CoreMLSigLIPImageEmbeddingProvider.shared
        )
    }

    func classify(image: UIImage, topK: Int) async throws -> [LabelScore] {
        guard topK > 0 else { return [] }

        let imageEmbedding = try await imageEmbeddingProvider.imageEmbedding(for: image)
        let normalizedImageEmbedding = ImageTextSimilarity.normalized(imageEmbedding)
        let candidateEmbeddings = try loadCandidateEmbeddings()

        return candidateEmbeddings
            .map { item in
                LabelScore(
                    label: item.label,
                    score: ImageTextSimilarity.dotProduct(normalizedImageEmbedding, item.embedding)
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    lhs.label < rhs.label
                } else {
                    lhs.score > rhs.score
                }
            }
            .prefix(topK)
            .map { $0 }
    }

    func prewarm() async throws {
        try await imageEmbeddingProvider.prewarm()
        _ = try loadCandidateEmbeddings()
    }

    private func loadCandidateEmbeddings() throws -> [CandidateEmbedding] {
        candidateEmbeddingsLock.lock()
        if let cachedCandidateEmbeddings {
            candidateEmbeddingsLock.unlock()
            return cachedCandidateEmbeddings
        }
        candidateEmbeddingsLock.unlock()

        let embeddings = try textEmbeddingStoreLoader().items.map { item in
            CandidateEmbedding(
                label: item.label,
                embedding: ImageTextSimilarity.normalized(item.embedding)
            )
        }

        candidateEmbeddingsLock.lock()
        defer { candidateEmbeddingsLock.unlock() }
        if let cachedCandidateEmbeddings {
            return cachedCandidateEmbeddings
        }
        cachedCandidateEmbeddings = embeddings
        return embeddings
    }
}
