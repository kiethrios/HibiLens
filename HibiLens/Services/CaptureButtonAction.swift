enum CaptureCameraState: Equatable {
    case loading
    case running
    case denied
    case unavailable
}

enum CaptureButtonAction: Equatable {
    case capture
    case showMessage(String)
    case ignore

    static func resolve(
        cameraState: CaptureCameraState,
        isBusy: Bool,
        hasLiftPreview: Bool
    ) -> CaptureButtonAction {
        if isBusy || hasLiftPreview {
            return .ignore
        }

        switch cameraState {
        case .running:
            return .capture
        case .loading:
            return .showMessage(AppL10n.Capture.cameraStarting)
        case .denied:
            return .showMessage(AppL10n.Capture.cameraAccessNeededMessage)
        case .unavailable:
            return .showMessage(AppL10n.Capture.cannotCaptureNow)
        }
    }
}
