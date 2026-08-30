import AVFoundation

enum CapturePhotoConfiguration {
    static func prioritization(
        for maxPrioritization: AVCapturePhotoOutput.QualityPrioritization
    ) -> AVCapturePhotoOutput.QualityPrioritization {
        maxPrioritization
    }
}
