import CoreImage
import CoreML
import UIKit

actor CoreMLSigLIPImageEmbeddingProvider: SigLIPImageEmbeddingProviding {
    static let shared = CoreMLSigLIPImageEmbeddingProvider()

    private let modelName: String
    private let targetSize: CGSize
    private let bundle: Bundle
    private var model: MLModel?

    init(
        modelName: String = "siglip_base_patch16_224_image",
        targetSize: CGSize = CGSize(width: 224, height: 224),
        bundle: Bundle = .main
    ) {
        self.modelName = modelName
        self.targetSize = targetSize
        self.bundle = bundle
    }

    func prewarm() async throws {
        _ = try loadModel()
    }

    func imageEmbedding(for image: UIImage) async throws -> [Float] {
        let model = try loadModel()
        let inputType = model.modelDescription.inputDescriptionsByName["pixel_values"]?.type
        let inputFeatureValue = try Self.inputFeatureValue(
            for: image,
            targetSize: targetSize,
            inputType: inputType
        )
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "pixel_values": inputFeatureValue
        ])
        let output = try await model.prediction(from: provider)
        return try Self.imageEmbedding(from: output)
    }

    nonisolated static func inputFeatureValue(
        for image: UIImage,
        targetSize: CGSize,
        inputType: MLFeatureType?
    ) throws -> MLFeatureValue {
        guard let inputType else {
            throw CoreMLSigLIPImageEmbeddingError.missingPixelValuesInput
        }

        switch inputType {
        case .image:
            return try MLFeatureValue(pixelBuffer: SigLIPImagePreprocessor.pixelBuffer(
                from: image,
                targetSize: targetSize
            ))
        case .multiArray:
            return try MLFeatureValue(multiArray: SigLIPImagePreprocessor.multiArray(
                from: image,
                targetSize: targetSize
            ))
        default:
            throw CoreMLSigLIPImageEmbeddingError.unsupportedPixelValuesInput(inputType)
        }
    }

    nonisolated static func imageEmbedding(from output: MLFeatureProvider) throws -> [Float] {
        if let embedding = output.featureValue(for: "image_embeds")?.multiArrayValue?.floatArray() {
            return try validatedEmbedding(embedding)
        }
        if let embedding = output.featureValue(for: "var_0")?.multiArrayValue?.floatArray() {
            return try validatedEmbedding(embedding)
        }
        throw CoreMLSigLIPImageEmbeddingError.missingEmbeddingOutput
    }

    nonisolated private static func validatedEmbedding(_ embedding: [Float]) throws -> [Float] {
        guard !embedding.isEmpty else {
            throw CoreMLSigLIPImageEmbeddingError.invalidEmbedding
        }
        return embedding
    }

    private func loadModel() throws -> MLModel {
        if let model {
            return model
        }
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw CoreMLSigLIPImageEmbeddingError.missingModel(modelName)
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let loaded = try MLModel(contentsOf: url, configuration: configuration)
        model = loaded
        return loaded
    }
}

enum CoreMLSigLIPImageEmbeddingError: LocalizedError {
    case missingModel(String)
    case invalidImage
    case missingEmbeddingOutput
    case invalidEmbedding
    case missingPixelValuesInput
    case unsupportedPixelValuesInput(MLFeatureType)

    var errorDescription: String? {
        switch self {
        case .missingModel(let modelName):
            "Missing bundled SigLIP image model: \(modelName).mlmodelc"
        case .invalidImage:
            "The image could not be prepared for SigLIP."
        case .missingEmbeddingOutput:
            "The SigLIP Core ML model did not return an image embedding output."
        case .invalidEmbedding:
            "The SigLIP Core ML model returned an empty image embedding."
        case .missingPixelValuesInput:
            "The SigLIP Core ML model does not declare a pixel_values input."
        case .unsupportedPixelValuesInput(let inputType):
            "The SigLIP Core ML model declares an unsupported pixel_values input type: \(inputType)."
        }
    }
}

enum SigLIPImagePreprocessor {
    nonisolated private static let ciContext = CIContext()

    nonisolated static func pixelBuffer(from image: UIImage, targetSize: CGSize) throws -> CVPixelBuffer {
        let prepared = try preparedImage(from: image, targetSize: targetSize)
        let targetWidth = Int(targetSize.width)
        let targetHeight = Int(targetSize.height)
        guard targetWidth > 0, targetHeight > 0 else {
            throw CoreMLSigLIPImageEmbeddingError.invalidImage
        }

        var output: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        CVPixelBufferCreate(
            nil,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32ARGB,
            attributes,
            &output
        )
        guard let output else {
            throw CoreMLSigLIPImageEmbeddingError.invalidImage
        }

        ciContext.render(prepared, to: output)
        return output
    }

    nonisolated static func multiArray(from image: UIImage, targetSize: CGSize) throws -> MLMultiArray {
        let pixelBuffer = try pixelBuffer(from: image, targetSize: targetSize)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let output = try MLMultiArray(
            shape: [1, 3, NSNumber(value: height), NSNumber(value: width)],
            dataType: .float32
        )

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw CoreMLSigLIPImageEmbeddingError.invalidImage
        }

        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                output[[0, 0, NSNumber(value: y), NSNumber(value: x)]] = normalizedChannel(bytes[offset + 1])
                output[[0, 1, NSNumber(value: y), NSNumber(value: x)]] = normalizedChannel(bytes[offset + 2])
                output[[0, 2, NSNumber(value: y), NSNumber(value: x)]] = normalizedChannel(bytes[offset + 3])
            }
        }

        return output
    }

    nonisolated private static func preparedImage(from image: UIImage, targetSize: CGSize) throws -> CIImage {
        let ciImage: CIImage?
        if let sourceCIImage = CIImage(image: image) {
            ciImage = sourceCIImage
        } else if let cgImage = image.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        } else {
            ciImage = nil
        }

        guard let prepared = ciImage?
            .oriented(forExifOrientation: Int32(image.imageOrientation.cgImagePropertyOrientation.rawValue))
            .cropToSquare()?
            .resize(size: targetSize) else {
            throw CoreMLSigLIPImageEmbeddingError.invalidImage
        }

        return prepared
    }

    nonisolated private static func normalizedChannel(_ value: UInt8) -> NSNumber {
        NSNumber(value: (Float(value) / 255.0 - 0.5) / 0.5)
    }
}
