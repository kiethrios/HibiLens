import CoreImage
import UIKit
import Vision

struct SubjectLiftPreview {
    let originalImage: UIImage
    let fullFrameImage: UIImage
    let processedImageData: Data
    let previewImage: UIImage
    let cardImageData: Data
    let cardPreviewImage: UIImage
    let maskImage: UIImage

    var liftedObjectRecognitionImage: UIImage {
        cardPreviewImage
    }
}

enum SubjectLiftCompletionAction: Equatable {
    case hold
    case openNewCard
}

enum SubjectLiftAnimationPhase {
    case glowOnOriginal
    case backgroundFade
    case settled

    var completionAction: SubjectLiftCompletionAction {
        self == .settled ? .openNewCard : .hold
    }

    var showsOriginalPhoto: Bool {
        switch self {
        case .glowOnOriginal, .backgroundFade:
            true
        case .settled:
            false
        }
    }

    var showsOrbitingGlow: Bool {
        self == .glowOnOriginal
    }

    var backgroundOpacity: Double {
        switch self {
        case .glowOnOriginal:
            1
        case .backgroundFade, .settled:
            0
        }
    }

    var originalPhotoOpacity: Double {
        switch self {
        case .glowOnOriginal:
            1
        case .backgroundFade:
            0.22
        case .settled:
            0
        }
    }

    var subjectScale: CGFloat {
        switch self {
        case .glowOnOriginal:
            1.02
        case .backgroundFade:
            1
        case .settled:
            0.98
        }
    }

    var subjectYOffset: CGFloat {
        switch self {
        case .glowOnOriginal:
            -8
        case .backgroundFade:
            -2
        case .settled:
            0
        }
    }

    var staticGlowOpacity: Double {
        switch self {
        case .glowOnOriginal:
            0.42
        case .backgroundFade:
            0.26
        case .settled:
            0.16
        }
    }
}

enum SubjectLiftProcessingError: LocalizedError {
    case invalidImage
    case noSubjectDetected
    case cutoutCreationFailed
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            AppL10n.SubjectLift.invalidImage
        case .noSubjectDetected:
            AppL10n.SubjectLift.noSubjectDetected
        case .cutoutCreationFailed:
            AppL10n.SubjectLift.cutoutCreationFailed
        case .imageEncodingFailed:
            AppL10n.SubjectLift.imageEncodingFailed
        }
    }
}

final class SubjectLiftProcessor {
    func process(_ image: UIImage, cardRotationAngle: CGFloat? = nil) async throws -> SubjectLiftPreview {
        try await Task.detached(priority: .userInitiated) {
            let normalizedImage = CaptureImageOrientationNormalizer.normalizeForSubjectLift(image)
            guard let cgImage = normalizedImage.cgImage else {
                throw SubjectLiftProcessingError.invalidImage
            }

            let requestHandler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .up,
                options: [:]
            )
            let request = VNGenerateForegroundInstanceMaskRequest()
            try requestHandler.perform([request])

            guard
                let observation = request.results?.first,
                !observation.allInstances.isEmpty
            else {
                throw SubjectLiftProcessingError.noSubjectDetected
            }

            let fullFramePixelBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: requestHandler,
                croppedToInstancesExtent: false
            )

            let subjectPixelBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: requestHandler,
                croppedToInstancesExtent: true
            )

            let context = CIContext(options: nil)
            let fullFrameCIImage = CIImage(cvPixelBuffer: fullFramePixelBuffer)
            let subjectCIImage = CIImage(cvPixelBuffer: subjectPixelBuffer)
            guard let fullFrameCGImage = context.createCGImage(fullFrameCIImage, from: fullFrameCIImage.extent) else {
                throw SubjectLiftProcessingError.cutoutCreationFailed
            }
            guard let subjectCGImage = context.createCGImage(subjectCIImage, from: subjectCIImage.extent) else {
                throw SubjectLiftProcessingError.cutoutCreationFailed
            }

            let fullFrameImage = UIImage(
                cgImage: fullFrameCGImage,
                scale: normalizedImage.scale,
                orientation: .up
            )
            let previewImage = UIImage(cgImage: subjectCGImage, scale: normalizedImage.scale, orientation: .up)
            let cardPreviewImage = CaptureImageOrientationNormalizer.normalizeForCard(
                previewImage,
                rotationAngle: cardRotationAngle
            )
            guard let processedImageData = previewImage.pngData() else {
                throw SubjectLiftProcessingError.imageEncodingFailed
            }
            guard let cardImageData = cardPreviewImage.pngData() else {
                throw SubjectLiftProcessingError.imageEncodingFailed
            }

            return SubjectLiftPreview(
                originalImage: normalizedImage,
                fullFrameImage: fullFrameImage,
                processedImageData: processedImageData,
                previewImage: previewImage,
                cardImageData: cardImageData,
                cardPreviewImage: cardPreviewImage,
                maskImage: previewImage
            )
        }.value
    }
}
