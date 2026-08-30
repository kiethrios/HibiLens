import CoreImage
import CoreML
import UIKit
import XCTest
@testable import JapCapture

final class SigLIPClassifierTests: XCTestCase {
    func testSharedImageLabelClassifierReusesCaptureInstance() {
        XCTAssertTrue(SharedImageLabelClassifier.capture === SharedImageLabelClassifier.capture)
    }

    func testSigLIPTextEmbeddingStoreDefaultsToObjectVocabularyResource() {
        XCTAssertEqual(
            SigLIPTextEmbeddingStore.defaultResourceName,
            "siglip-object-vocabulary-text-embeddings"
        )
    }

    func testSigLIPTextEmbeddingStoreDecodesLabelsAndEmbeddings() throws {
        let json = """
        {
          "modelID": "google/siglip-base-patch16-224",
          "license": "apache-2.0",
          "embeddingDimension": 3,
          "items": [
            {
              "label": "cup",
              "prompts": ["A photo of a cup"],
              "embedding": [0.1, 0.2, 0.3]
            },
            {
              "label": "bottle",
              "prompts": ["A photo of a bottle"],
              "embedding": [0.3, 0.2, 0.1]
            }
          ]
        }
        """.data(using: .utf8)!

        let store = try SigLIPTextEmbeddingStore.decode(from: json)

        XCTAssertEqual(store.modelID, "google/siglip-base-patch16-224")
        XCTAssertEqual(store.license, "apache-2.0")
        XCTAssertEqual(store.embeddingDimension, 3)
        XCTAssertEqual(store.items.map(\.label), ["cup", "bottle"])
        XCTAssertEqual(store.embedding(for: "cup"), [0.1, 0.2, 0.3])
    }

    func testSigLIPTextEmbeddingStoreRejectsLabelsWithTrailingWhitespace() throws {
        let json = """
        {
          "modelID": "google/siglip-base-patch16-224",
          "license": "apache-2.0",
          "embeddingDimension": 3,
          "items": [
            {
              "label": "cup ",
              "prompts": ["A photo of a cup"],
              "embedding": [0.1, 0.2, 0.3]
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try SigLIPTextEmbeddingStore.decode(from: json)) { error in
            XCTAssertEqual(
                error as? SigLIPTextEmbeddingStoreError,
                .invalidLabelWhitespace("cup ")
            )
        }
    }

    func testSigLIPImageLabelClassifierRanksTextEmbeddingsByImageEmbedding() async throws {
        let json = """
        {
          "modelID": "google/siglip-base-patch16-224",
          "license": "apache-2.0",
          "embeddingDimension": 2,
          "items": [
            { "label": "cup", "prompts": ["A photo of a cup"], "embedding": [1.0, 0.0] },
            { "label": "bottle", "prompts": ["A photo of a bottle"], "embedding": [0.0, 1.0] },
            { "label": "chair", "prompts": ["A photo of a chair"], "embedding": [0.7, 0.3] }
          ]
        }
        """.data(using: .utf8)!
        let store = try SigLIPTextEmbeddingStore.decode(from: json)
        let image = UIImage()
        let classifier = SigLIPImageLabelClassifier(
            textEmbeddingStore: store,
            imageEmbeddingProvider: StubSigLIPImageEmbeddingProvider(embedding: [1.0, 0.0])
        )

        let scores = try await classifier.classify(image: image, topK: 2)

        XCTAssertEqual(scores.map(\.label), ["cup", "chair"])
        XCTAssertEqual(scores[0].score, 1.0, accuracy: 0.001)
    }

    func testSigLIPImageLabelClassifierPrewarmsImageEmbeddingProvider() async throws {
        let json = """
        {
          "modelID": "google/siglip-base-patch16-224",
          "license": "apache-2.0",
          "embeddingDimension": 2,
          "items": [
            { "label": "cup", "prompts": ["A photo of a cup"], "embedding": [1.0, 0.0] }
          ]
        }
        """.data(using: .utf8)!
        let store = try SigLIPTextEmbeddingStore.decode(from: json)
        let provider = StubSigLIPImageEmbeddingProvider(embedding: [1.0, 0.0])
        let classifier = SigLIPImageLabelClassifier(
            textEmbeddingStore: store,
            imageEmbeddingProvider: provider
        )

        try await classifier.prewarm()

        let prewarmCallCount = await provider.prewarmCallCount
        XCTAssertEqual(prewarmCallCount, 1)
    }

    func testSigLIPImagePreprocessorProducesSquarePixelBuffer() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        }

        let pixelBuffer = try SigLIPImagePreprocessor.pixelBuffer(from: image, targetSize: CGSize(width: 224, height: 224))

        XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 224)
        XCTAssertEqual(CVPixelBufferGetHeight(pixelBuffer), 224)
    }

    func testSigLIPImagePreprocessorProducesImageMultiArray() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        }

        let multiArray = try SigLIPImagePreprocessor.multiArray(from: image, targetSize: CGSize(width: 224, height: 224))

        XCTAssertEqual(multiArray.shape, [1, 3, 224, 224])
        XCTAssertEqual(multiArray.count, 1 * 3 * 224 * 224)
        XCTAssertFalse(multiArray.floatArray().isEmpty)
    }

    func testCoreMLSigLIPImageInputRejectsMissingPixelValuesType() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }

        XCTAssertThrowsError(try CoreMLSigLIPImageEmbeddingProvider.inputFeatureValue(
            for: image,
            targetSize: CGSize(width: 8, height: 8),
            inputType: nil
        )) { error in
            guard case CoreMLSigLIPImageEmbeddingError.missingPixelValuesInput = error else {
                return XCTFail("Expected missingPixelValuesInput, got \(error)")
            }
        }
    }

    func testSigLIPImagePreprocessorAppliesImageOrientationBeforeCropping() throws {
        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 80))
            UIColor.green.setFill()
            context.fill(CGRect(x: 40, y: 0, width: 40, height: 80))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 80, y: 0, width: 40, height: 80))
        }
        let orientedImage = UIImage(
            cgImage: try XCTUnwrap(sourceImage.cgImage),
            scale: sourceImage.scale,
            orientation: .right
        )
        let targetSize = CGSize(width: 12, height: 12)
        let expectedOrientedPixelBuffer = try expectedPixelBuffer(
            from: orientedImage,
            targetSize: targetSize,
            appliesOrientation: true
        )
        let expectedUnorientedPixelBuffer = try expectedPixelBuffer(
            from: orientedImage,
            targetSize: targetSize,
            appliesOrientation: false
        )

        let pixelBuffer = try SigLIPImagePreprocessor.pixelBuffer(from: orientedImage, targetSize: targetSize)

        XCTAssertEqual(pixelBytes(in: pixelBuffer), pixelBytes(in: expectedOrientedPixelBuffer))
        XCTAssertNotEqual(pixelBytes(in: pixelBuffer), pixelBytes(in: expectedUnorientedPixelBuffer))
    }

    func testCoreMLSigLIPImageEmbeddingRejectsEmptyImageEmbedsOutput() throws {
        let output = try MLDictionaryFeatureProvider(dictionary: [
            "image_embeds": MLFeatureValue(multiArray: try MLMultiArray(shape: [0], dataType: .float32))
        ])

        XCTAssertThrowsError(try CoreMLSigLIPImageEmbeddingProvider.imageEmbedding(from: output)) { error in
            guard case CoreMLSigLIPImageEmbeddingError.invalidEmbedding = error else {
                return XCTFail("Expected invalidEmbedding, got \(error)")
            }
        }
    }

    func testCoreMLSigLIPImageEmbeddingRejectsEmptyVar0Output() throws {
        let output = try MLDictionaryFeatureProvider(dictionary: [
            "var_0": MLFeatureValue(multiArray: try MLMultiArray(shape: [0], dataType: .float32))
        ])

        XCTAssertThrowsError(try CoreMLSigLIPImageEmbeddingProvider.imageEmbedding(from: output)) { error in
            guard case CoreMLSigLIPImageEmbeddingError.invalidEmbedding = error else {
                return XCTFail("Expected invalidEmbedding, got \(error)")
            }
        }
    }
}

private func expectedPixelBuffer(
    from image: UIImage,
    targetSize: CGSize,
    appliesOrientation: Bool
) throws -> CVPixelBuffer {
    let ciImage: CIImage?
    if let sourceCIImage = CIImage(image: image) {
        ciImage = sourceCIImage
    } else if let cgImage = image.cgImage {
        ciImage = CIImage(cgImage: cgImage)
    } else {
        ciImage = nil
    }

    let orientedImage = appliesOrientation
        ? ciImage?.oriented(forExifOrientation: Int32(image.imageOrientation.cgImagePropertyOrientation.rawValue))
        : ciImage

    let prepared = try XCTUnwrap(orientedImage?
        .cropToSquare()?
        .resize(size: targetSize))

    var output: CVPixelBuffer?
    let attributes = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ] as CFDictionary
    CVPixelBufferCreate(
        nil,
        Int(targetSize.width),
        Int(targetSize.height),
        kCVPixelFormatType_32ARGB,
        attributes,
        &output
    )
    let pixelBuffer = try XCTUnwrap(output)
    CIContext().render(prepared, to: pixelBuffer)
    return pixelBuffer
}

private func pixelBytes(in pixelBuffer: CVPixelBuffer) -> [UInt8] {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!.assumingMemoryBound(to: UInt8.self)
    let bytesPerPixel = 4
    var bytes: [UInt8] = []
    bytes.reserveCapacity(width * height * bytesPerPixel)

    for y in 0..<height {
        let row = baseAddress.advanced(by: y * bytesPerRow)
        bytes.append(contentsOf: UnsafeBufferPointer(start: row, count: width * bytesPerPixel))
    }

    return bytes
}

private actor StubSigLIPImageEmbeddingProvider: SigLIPImageEmbeddingProviding {
    private let embedding: [Float]
    private(set) var prewarmCallCount = 0

    init(embedding: [Float]) {
        self.embedding = embedding
    }

    func prewarm() async throws {
        prewarmCallCount += 1
    }

    func imageEmbedding(for image: UIImage) async throws -> [Float] {
        embedding
    }
}
