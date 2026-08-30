import UIKit
import XCTest
import AVFoundation
@testable import JapCapture

final class CaptureSubjectLiftPreviewTests: XCTestCase {
    func testVisualRecognitionUsesLiftedCardPreviewImageOnly() throws {
        let originalImage = try XCTUnwrap(makeImage(color: .systemPink, size: CGSize(width: 20, height: 20)))
        let fullFrameImage = try XCTUnwrap(makeImage(color: .systemOrange, size: CGSize(width: 22, height: 22)))
        let previewImage = try XCTUnwrap(makeImage(color: .systemTeal, size: CGSize(width: 24, height: 24)))
        let cardPreviewImage = try XCTUnwrap(makeImage(color: .systemGreen, size: CGSize(width: 26, height: 26)))
        let preview = SubjectLiftPreview(
            originalImage: originalImage,
            fullFrameImage: fullFrameImage,
            processedImageData: try XCTUnwrap(previewImage.pngData()),
            previewImage: previewImage,
            cardImageData: try XCTUnwrap(cardPreviewImage.pngData()),
            cardPreviewImage: cardPreviewImage,
            maskImage: previewImage
        )

        let recognitionImage = preview.liftedObjectRecognitionImage

        XCTAssertEqual(recognitionImage.pngData(), cardPreviewImage.pngData())
        XCTAssertNotEqual(recognitionImage.pngData(), originalImage.pngData())
        XCTAssertNotEqual(recognitionImage.pngData(), fullFrameImage.pngData())
    }

    func testLocalImageLabelLogMessagePrintsLabelsAndScoresOnly() {
        let message = LocalImageLabelLogMessage.make(scores: [
            LabelScore(label: "cup", score: 0.31),
            LabelScore(label: "bottle", score: 0.27)
        ])

        XCTAssertEqual(message, "[SigLIPImageLabelClassifier] labels=cup:0.310, bottle:0.270")
    }

    func testClassifierLogMessageIsBackendNeutral() {
        let message = LocalImageLabelLogMessage.make(
            backendName: "SigLIPImageLabelClassifier",
            scores: [
                LabelScore(label: "cup", score: 0.42),
                LabelScore(label: "bottle", score: 0.31)
            ]
        )

        XCTAssertEqual(
            message,
            "[SigLIPImageLabelClassifier] labels=cup:0.420, bottle:0.310"
        )
    }

    func testLocalImageLabelLogMessageLimitsLabelsToFirstFive() {
        let scores = (1...12).map { LabelScore(label: "label\($0)", score: Float($0) / 100) }

        let message = LocalImageLabelLogMessage.make(scores: scores)

        XCTAssertEqual(
            message,
            "[SigLIPImageLabelClassifier] labels=label1:0.010, label2:0.020, label3:0.030, label4:0.040, label5:0.050"
        )
    }

    func testCaptureDraftCandidateBuilderCreatesOneDraftPerLabelWithoutFakeKanaOrKanji() throws {
        let imageData = try XCTUnwrap(makeImageData(color: .systemIndigo))
        let previewImage = try XCTUnwrap(UIImage(data: imageData))

        let drafts = CaptureDraftCandidateBuilder.makeDrafts(
            labels: ["microphone", "camera", "machine"],
            imageData: imageData,
            previewImage: previewImage
        )

        XCTAssertEqual(drafts.count, 3)
        XCTAssertEqual(drafts.map(\.metadata.japaneseText), ["microphone", "camera", "machine"])
        XCTAssertEqual(drafts.map(\.metadata.kanaText), ["", "", ""])
        XCTAssertEqual(drafts.map(\.metadata.kanjiText), ["", "", ""])
        XCTAssertEqual(drafts.map(\.metadata.romajiText), ["microphone", "camera", "machine"])
        XCTAssertEqual(drafts.map(\.metadata.translationEnglish), ["microphone", "camera", "machine"])
        XCTAssertEqual(drafts.map(\.metadata.translationChinese), ["microphone", "camera", "machine"])
        XCTAssertTrue(drafts.allSatisfy { $0.imageData == imageData })
    }

    func testCaptureDraftCandidateBuilderCreatesDraftsFromVocabularyCandidates() throws {
        let imageData = try XCTUnwrap(makeImageData(color: .systemIndigo))
        let previewImage = try XCTUnwrap(UIImage(data: imageData))
        let candidates = [
            VocabularyCandidate(
                jmdictSeq: "1050390",
                japanese: "コップ",
                kana: "コップ",
                romaji: "koppu",
                english: "cup",
                zhHans: "杯子",
                partOfSpeech: ["noun"],
                priority: 95
            ),
            VocabularyCandidate(
                jmdictSeq: "2057330",
                japanese: "マグカップ",
                kana: "マグカップ",
                romaji: "magukappu",
                english: "mug",
                zhHans: "马克杯",
                partOfSpeech: ["noun"],
                priority: 94
            )
        ]

        let drafts = CaptureDraftCandidateBuilder.makeDrafts(
            candidates: candidates,
            fallbackLabels: ["cup"],
            imageData: imageData,
            previewImage: previewImage
        )

        XCTAssertEqual(drafts.count, 2)
        XCTAssertEqual(drafts.map(\.metadata.japaneseText), ["コップ", "マグカップ"])
        XCTAssertEqual(drafts.map(\.metadata.kanaText), ["コップ", "マグカップ"])
        XCTAssertEqual(drafts.map(\.metadata.romajiText), ["koppu", "magukappu"])
        XCTAssertEqual(drafts.map(\.metadata.translationEnglish), ["cup", "mug"])
        XCTAssertEqual(drafts.map(\.metadata.translationChinese), ["杯子", "马克杯"])
        XCTAssertTrue(drafts.allSatisfy { $0.imageData == imageData })
    }

    func testCaptureDraftCandidateBuilderFallsBackToTopLabelWhenLookupHasNoCandidates() throws {
        let imageData = try XCTUnwrap(makeImageData(color: .systemGray))
        let previewImage = try XCTUnwrap(UIImage(data: imageData))

        let drafts = CaptureDraftCandidateBuilder.makeDrafts(
            candidates: [],
            fallbackLabels: ["unknown object", "second label"],
            imageData: imageData,
            previewImage: previewImage
        )

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.metadata.japaneseText, "unknown object")
        XCTAssertEqual(drafts.first?.metadata.kanaText, "")
        XCTAssertEqual(drafts.first?.metadata.kanjiText, "")
        XCTAssertEqual(drafts.first?.metadata.translationEnglish, "unknown object")
    }

    func testSubjectLiftPhasesFollowGlowFadeThenFullScreenSettleSequence() {
        XCTAssertTrue(SubjectLiftAnimationPhase.glowOnOriginal.showsOriginalPhoto)
        XCTAssertTrue(SubjectLiftAnimationPhase.glowOnOriginal.showsOrbitingGlow)
        XCTAssertEqual(SubjectLiftAnimationPhase.glowOnOriginal.backgroundOpacity, 1)

        XCTAssertTrue(SubjectLiftAnimationPhase.backgroundFade.showsOriginalPhoto)
        XCTAssertFalse(SubjectLiftAnimationPhase.backgroundFade.showsOrbitingGlow)
        XCTAssertEqual(SubjectLiftAnimationPhase.backgroundFade.backgroundOpacity, 0)

        XCTAssertFalse(SubjectLiftAnimationPhase.settled.showsOriginalPhoto)
        XCTAssertFalse(SubjectLiftAnimationPhase.settled.showsOrbitingGlow)
        XCTAssertEqual(SubjectLiftAnimationPhase.settled.completionAction, .openNewCard)
    }

    func testCaptureButtonActionAllowsCaptureOnlyWhenCameraIsRunning() {
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .running, isBusy: false, hasLiftPreview: false),
            .capture
        )
    }

    func testCaptureButtonActionExplainsWhyTapCannotCapture() {
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .loading, isBusy: false, hasLiftPreview: false),
            .showMessage("Camera is still starting. Please wait a moment and try again.")
        )
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .denied, isBusy: false, hasLiftPreview: false),
            .showMessage("Enable camera access in Settings to capture objects and words.")
        )
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .unavailable, isBusy: false, hasLiftPreview: false),
            .showMessage("This device or simulator cannot capture a photo right now.")
        )
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .running, isBusy: true, hasLiftPreview: false),
            .ignore
        )
        XCTAssertEqual(
            CaptureButtonAction.resolve(cameraState: .running, isBusy: false, hasLiftPreview: true),
            .ignore
        )
    }

    func testPhotoQualityPrioritizationUsesHighestSupportedQuality() {
        XCTAssertEqual(
            CapturePhotoConfiguration.prioritization(for: .quality),
            .quality
        )
        XCTAssertEqual(
            CapturePhotoConfiguration.prioritization(for: .balanced),
            .balanced
        )
        XCTAssertEqual(
            CapturePhotoConfiguration.prioritization(for: .speed),
            .speed
        )
    }

    func testCaptureCardRotationUsesLandscapeDeviceOrientationOnly() {
        XCTAssertEqual(CaptureCardRotation.angle(for: .landscapeLeft), -90)
        XCTAssertEqual(CaptureCardRotation.angle(for: .landscapeRight), 90)
        XCTAssertNil(CaptureCardRotation.angle(for: .portrait))
        XCTAssertNil(CaptureCardRotation.angle(for: .portraitUpsideDown))
        XCTAssertNil(CaptureCardRotation.angle(for: .faceUp))
        XCTAssertNil(CaptureCardRotation.angle(for: .faceDown))
        XCTAssertNil(CaptureCardRotation.angle(for: .unknown))
    }

    func testCaptureCardRotationCanUseMotionGravityWhenDeviceOrientationIsUnavailable() {
        XCTAssertEqual(CaptureCardRotation.angle(forGravityX: -0.92, y: -0.08), -90)
        XCTAssertEqual(CaptureCardRotation.angle(forGravityX: 0.92, y: 0.08), 90)
        XCTAssertNil(CaptureCardRotation.angle(forGravityX: 0.04, y: -0.96))
        XCTAssertNil(CaptureCardRotation.angle(forGravityX: 0.08, y: 0.91))
        XCTAssertNil(CaptureCardRotation.angle(forGravityX: 0.38, y: 0.32))
    }

    func testCaptureImageOrientationNormalizerKeepsUprightLandscapeImagesLandscape() throws {
        let landscape = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180)).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        }

        let normalized = CaptureImageOrientationNormalizer.normalizeForSubjectLift(landscape)

        XCTAssertGreaterThan(normalized.size.width, normalized.size.height)
        XCTAssertEqual(normalized.imageOrientation, UIImage.Orientation.up)
    }

    func testCaptureImageOrientationNormalizerLeavesPortraitImagesUpright() throws {
        let portrait = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 320)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 180, height: 320))
        }

        let normalized = CaptureImageOrientationNormalizer.normalizeForSubjectLift(portrait)

        XCTAssertEqual(normalized.size.width, portrait.size.width)
        XCTAssertEqual(normalized.size.height, portrait.size.height)
        XCTAssertEqual(normalized.imageOrientation, UIImage.Orientation.up)
    }

    func testCaptureImageOrientationNormalizerRotatesOnlyCardImageWhenRequested() throws {
        let landscape = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180)).image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        }

        let rotated = CaptureImageOrientationNormalizer.normalizeForCard(landscape, rotationAngle: 90)

        XCTAssertEqual(rotated.imageOrientation, UIImage.Orientation.up)
        XCTAssertEqual(rotated.size.width, 180, accuracy: 0.5)
        XCTAssertEqual(rotated.size.height, 320, accuracy: 0.5)
    }

    func testCaptureImageOrientationNormalizerLeavesCardImageUnchangedWithoutRotation() throws {
        let landscape = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180)).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        }

        let normalized = CaptureImageOrientationNormalizer.normalizeForCard(landscape, rotationAngle: nil)

        XCTAssertEqual(normalized.size.width, landscape.size.width)
        XCTAssertEqual(normalized.size.height, landscape.size.height)
        XCTAssertEqual(normalized.imageOrientation, UIImage.Orientation.up)
    }

    private func makeImageData(color: UIColor) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }
        return image.pngData()
    }

    private func makeImage(color: UIColor, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
