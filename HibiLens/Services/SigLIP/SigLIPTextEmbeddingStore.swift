import Foundation

struct SigLIPTextEmbeddingStore: Decodable {
    static let defaultResourceName = "siglip-object-vocabulary-text-embeddings"

    let modelID: String
    let license: String
    let embeddingDimension: Int
    let items: [Item]

    struct Item: Decodable {
        let label: String
        let prompts: [String]
        let embedding: [Float]
    }

    static func decode(from data: Data) throws -> SigLIPTextEmbeddingStore {
        let store = try JSONDecoder().decode(SigLIPTextEmbeddingStore.self, from: data)
        try store.validate()
        return store
    }

    static func loadFromBundle(
        resourceName: String = defaultResourceName,
        bundle: Bundle = .main
    ) throws -> SigLIPTextEmbeddingStore {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw SigLIPTextEmbeddingStoreError.missingResource(resourceName)
        }
        return try decode(from: Data(contentsOf: url))
    }

    func embedding(for label: String) -> [Float]? {
        items.first { $0.label == label }?.embedding
    }

    private func validate() throws {
        guard embeddingDimension > 0 else {
            throw SigLIPTextEmbeddingStoreError.invalidEmbeddingDimension
        }

        var seenLabels = Set<String>()
        for item in items {
            let trimmedLabel = item.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLabel.isEmpty else {
                throw SigLIPTextEmbeddingStoreError.emptyLabel
            }
            guard trimmedLabel == item.label else {
                throw SigLIPTextEmbeddingStoreError.invalidLabelWhitespace(item.label)
            }
            guard seenLabels.insert(item.label).inserted else {
                throw SigLIPTextEmbeddingStoreError.duplicateLabel(item.label)
            }
            guard item.embedding.count == embeddingDimension else {
                throw SigLIPTextEmbeddingStoreError.embeddingDimensionMismatch(item.label)
            }
        }
    }
}

enum SigLIPTextEmbeddingStoreError: LocalizedError, Equatable {
    case missingResource(String)
    case invalidEmbeddingDimension
    case emptyLabel
    case invalidLabelWhitespace(String)
    case duplicateLabel(String)
    case embeddingDimensionMismatch(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            "Missing bundled SigLIP text embedding resource: \(name).json"
        case .invalidEmbeddingDimension:
            "SigLIP text embedding dimension must be greater than zero."
        case .emptyLabel:
            "SigLIP text embedding labels cannot be empty."
        case .invalidLabelWhitespace(let label):
            "SigLIP text embedding labels cannot include leading or trailing whitespace: \(label)."
        case .duplicateLabel(let label):
            "Duplicate SigLIP text embedding label: \(label)."
        case .embeddingDimensionMismatch(let label):
            "SigLIP text embedding dimension mismatch for label: \(label)."
        }
    }
}
