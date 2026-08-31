@preconcurrency import AVFoundation
import Combine
import CoreMotion
import OSLog
import UIKit

struct CapturePhotoResult {
    let image: UIImage
    let cardRotationAngle: CGFloat?
}

final class CameraService: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var state: CaptureCameraState = .loading
    private let sessionQueue = DispatchQueue(label: "com.example.HibiLens.camera-session")
    private let logger = Logger(subsystem: "com.example.HibiLens", category: "Camera")
    private var isConfigured = false
    private var photoOutput = AVCapturePhotoOutput()
    private var lastUsableDeviceOrientation: UIDeviceOrientation = .portrait
    private let motionManager = CMMotionManager()
    private var observers: [NSObjectProtocol] = []
    private var activePhotoDelegates: [Int64: PhotoCaptureDelegate] = [:]

    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateLastUsableDeviceOrientation(UIDevice.current.orientation)
        startMotionUpdates()
        registerObservers()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        motionManager.stopDeviceMotionUpdates()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func prepare() {
        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        log("auth=\(authorization.debugName)")

        switch authorization {
        case .authorized:
            configureAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }

                Task { @MainActor in
                    if granted {
                        self.log("auth=granted")
                        self.configureAndStartSession()
                    } else {
                        self.state = .denied
                        self.log("auth=denied")
                    }
                }
            }
        case .denied, .restricted:
            state = .denied
            log("auth=\(authorization.debugName)")
        @unknown default:
            state = .unavailable
            log("auth=unknown")
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> CapturePhotoResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CapturePhotoResult, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CapturePhotoError.cameraUnavailable)
                    return
                }

                guard self.isConfigured, self.session.isRunning else {
                    continuation.resume(throwing: CapturePhotoError.cameraUnavailable)
                    return
                }

                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = CapturePhotoConfiguration.prioritization(
                    for: self.photoOutput.maxPhotoQualityPrioritization
                )
                let cardRotationAngle = self.cardRotationAngleForCurrentCapture()
                let delegate = PhotoCaptureDelegate { [weak self] uniqueID in
                    self?.sessionQueue.async {
                        self?.activePhotoDelegates[uniqueID] = nil
                    }
                } continuation: { result in
                    switch result {
                    case .success(let image):
                        continuation.resume(
                            returning: CapturePhotoResult(
                                image: image,
                                cardRotationAngle: cardRotationAngle
                            )
                        )
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }

                self.activePhotoDelegates[settings.uniqueID] = delegate
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    private func configureAndStartSession() {
        state = .loading
        log("configuring")

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let configured = self.configureSessionIfNeeded()

            guard configured else {
                Task { @MainActor in
                    self.state = .unavailable
                    self.log("config-failed")
                }
                return
            }

            guard !self.session.isRunning else {
                Task { @MainActor in
                    self.state = .running
                    self.log("already-running")
                }
                return
            }

            self.session.startRunning()

            Task { @MainActor in
                self.state = .running
                self.log("running inputs=\(self.session.inputs.count) outputs=\(self.session.outputs.count)")
            }
        }
    }

    private func configureSessionIfNeeded() -> Bool {
        guard !isConfigured else { return true }

        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = bestBackCamera() else {
            logger.error("No back camera device available")
            return false
        }

        logger.info("Using camera device: \(device.localizedName, privacy: .public)")

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            logger.error("Failed to create AVCaptureDeviceInput")
            return false
        }

        guard session.canAddInput(input) else {
            logger.error("Session cannot add camera input")
            return false
        }

        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            logger.error("Session cannot add photo output")
            return false
        }

        session.addOutput(photoOutput)
        isConfigured = true
        return true
    }

    private func bestBackCamera() -> AVCaptureDevice? {
        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wide
        }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInDualCamera],
            mediaType: .video,
            position: .back
        )

        return discovery.devices.first ?? AVCaptureDevice.default(for: .video)
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            log("motion=unavailable")
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.12
        motionManager.startDeviceMotionUpdates()
        log("motion=started")
    }

    private func cardRotationAngleForCurrentCapture() -> CGFloat? {
        let motionAngle = currentMotionCardRotationAngle()
        let deviceOrientation = currentUsableDeviceOrientation()
        let deviceAngle = CaptureCardRotation.angle(for: deviceOrientation)
        let resolvedAngle = motionAngle ?? deviceAngle
        log(
            "card-rotation motion=\(motionAngle.debugDescription) device=\(deviceOrientation.debugName) angle=\(resolvedAngle.debugDescription)"
        )
        return resolvedAngle
    }

    private func currentMotionCardRotationAngle() -> CGFloat? {
        guard let gravity = motionManager.deviceMotion?.gravity else { return nil }
        return CaptureCardRotation.angle(forGravityX: gravity.x, y: gravity.y)
    }

    private func currentUsableDeviceOrientation() -> UIDeviceOrientation {
        let currentOrientation = UIDevice.current.orientation
        updateLastUsableDeviceOrientation(currentOrientation)
        log("card-orientation device=\(lastUsableDeviceOrientation.debugName)")
        return lastUsableDeviceOrientation
    }

    private func updateLastUsableDeviceOrientation(_ orientation: UIDeviceOrientation) {
        guard orientation == .portrait ||
            orientation == .portraitUpsideDown ||
            orientation == .landscapeLeft ||
            orientation == .landscapeRight
        else {
            return
        }

        lastUsableDeviceOrientation = orientation
    }

    private func registerObservers() {
        let notificationCenter = NotificationCenter.default

        observers.append(
            notificationCenter.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateLastUsableDeviceOrientation(UIDevice.current.orientation)
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: AVCaptureSession.runtimeErrorNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
                self?.logger.error("Runtime error: \(String(describing: error), privacy: .public)")
                self?.state = .unavailable
                self?.log("runtime-error=\(error?.code.rawValue ?? -1)")
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: AVCaptureSession.wasInterruptedNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                let reasonRawValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int ?? -1
                self?.logger.warning("Session interrupted: \(reasonRawValue)")
                self?.log("interrupted=\(reasonRawValue)")
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: AVCaptureSession.interruptionEndedNotification,
                object: session,
                queue: .main
            ) { [weak self] _ in
                self?.logger.info("Session interruption ended")
                self?.log("interruption-ended")
            }
        )
    }

    private func log(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        print("[CameraService] \(message)")
    }
}

private enum CapturePhotoError: Error {
    case cameraUnavailable
    case invalidImageData
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    nonisolated(unsafe) private let onFinish: (Int64) -> Void
    nonisolated(unsafe) private let continuation: (Result<UIImage, Error>) -> Void
    nonisolated(unsafe) private var hasResumed = false

    nonisolated init(
        onFinish: @escaping (Int64) -> Void,
        continuation: @escaping (Result<UIImage, Error>) -> Void
    ) {
        self.onFinish = onFinish
        self.continuation = continuation
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            resumeOnce(with: .failure(error))
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            resumeOnce(with: .failure(CapturePhotoError.invalidImageData))
            return
        }

        resumeOnce(with: .success(image))
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error {
            resumeOnce(with: .failure(error))
        }
        onFinish(resolvedSettings.uniqueID)
    }

    nonisolated private func resumeOnce(with result: Result<UIImage, Error>) {
        guard !hasResumed else { return }
        hasResumed = true
        continuation(result)
    }
}

private extension AVAuthorizationStatus {
    var debugName: String {
        switch self {
        case .authorized: "authorized"
        case .notDetermined: "notDetermined"
        case .denied: "denied"
        case .restricted: "restricted"
        @unknown default: "unknown"
        }
    }
}

private extension UIDeviceOrientation {
    var debugName: String {
        switch self {
        case .unknown: "unknown"
        case .portrait: "portrait"
        case .portraitUpsideDown: "portraitUpsideDown"
        case .landscapeLeft: "landscapeLeft"
        case .landscapeRight: "landscapeRight"
        case .faceUp: "faceUp"
        case .faceDown: "faceDown"
        @unknown default: "unknownDefault"
        }
    }
}
