import UIKit

enum CaptureCardRotation {
    nonisolated static func angle(for deviceOrientation: UIDeviceOrientation) -> CGFloat? {
        switch deviceOrientation {
        case .landscapeLeft:
            return -90
        case .landscapeRight:
            return 90
        case .portrait, .portraitUpsideDown, .unknown, .faceUp, .faceDown:
            return nil
        @unknown default:
            return nil
        }
    }

    nonisolated static func angle(forGravityX x: Double, y: Double) -> CGFloat? {
        let landscapeThreshold = 0.75
        let portraitThreshold = 0.75

        if x <= -landscapeThreshold {
            return angle(for: .landscapeLeft)
        }

        if x >= landscapeThreshold {
            return angle(for: .landscapeRight)
        }

        if y <= -portraitThreshold || y >= portraitThreshold {
            return nil
        }

        return nil
    }
}
