//
//  CameraService.swift
//  HibiLens
//

@preconcurrency import AVFoundation
import Combine
import CoreMotion
import OSLog
import UIKit

enum CameraStartupZoomCoordinator {
    static func startAtWide(
        applyWideBeforeStart: () -> Bool,
        startSession: () -> Void,
        confirmWideAfterStart: () -> Bool
    ) -> Bool {
        guard applyWideBeforeStart() else { return false }
        startSession()
        return confirmWideAfterStart()
    }
}

enum CameraZoomControlPresentation {
    static func visiblePresets(from presets: [CameraZoomPreset]) -> [CameraZoomPreset] {
        presets.count > 1 ? presets : []
    }
}

struct CapturePhotoResult {
    let image: UIImage
    let cardRotationAngle: CGFloat?
}

final class CameraService: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var state: CaptureCameraState = .loading
    @Published private(set) var availableZoomPresets: [CameraZoomPreset] = []
    @Published private(set) var selectedZoomPresetID: CameraLensKind = .wide
    @Published private(set) var isZoomTransitioning = false
    private let sessionQueue = DispatchQueue(label: "com.example.HibiLens.camera-session")
    private let logger = Logger(subsystem: "com.example.HibiLens", category: "Camera")
    private var isConfigured = false
    private var activeCameraDevice: AVCaptureDevice?
    private var configuredZoomPresets: [CameraZoomPreset] = []
    private var zoomSelection = CameraZoomSelectionState(selectedPresetID: .wide)
    private var pendingZoomTransitionID: UUID?
    private var activeZoomTransitionID: UUID?
    private var preparationID = UUID()
    private var hasStopped = false
    private let zoomRampRate: Float = 8
    private let zoomTargetTolerance: CGFloat = 0.03
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

    @MainActor func prepare() {
        preparationID = UUID()
        hasStopped = false
        pendingZoomTransitionID = nil
        zoomSelection = CameraZoomSelectionState(selectedPresetID: .wide)
        availableZoomPresets = []
        selectedZoomPresetID = .wide
        isZoomTransitioning = false

        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        log("auth=\(authorization.debugName)")

        switch authorization {
        case .authorized:
            configureAndStartSession()
        case .notDetermined:
            let requestedPreparationID = preparationID
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }

                Task { @MainActor in
                    guard self.preparationID == requestedPreparationID else { return }
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

    @MainActor func stop() {
        preparationID = UUID()
        hasStopped = true
        pendingZoomTransitionID = nil
        zoomSelection.cancelTransition()
        isZoomTransitioning = false

        sessionQueue.async { [self] in
            self.activeZoomTransitionID = nil
            if let device = self.activeCameraDevice {
                self.cancelZoomRamp(on: device)
            }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    @MainActor func selectZoomPreset(_ presetID: CameraLensKind) {
        guard !hasStopped,
              state == .running,
              let preset = availableZoomPresets.first(where: { $0.id == presetID }),
              let confirmedPreset = availableZoomPresets.first(where: { $0.id == zoomSelection.selectedPresetID }),
              zoomSelection.beginTransition(to: presetID)
        else {
            return
        }

        let transitionID = UUID()
        pendingZoomTransitionID = transitionID
        isZoomTransitioning = true

        sessionQueue.async { [weak self] in
            self?.startZoomTransition(
                to: preset,
                restoring: confirmedPreset,
                transitionID: transitionID
            )
        }
    }

    func capturePhoto(normalizedVisibleRect: CGRect?) async throws -> CapturePhotoResult {
        let requestedVisibleRect = normalizedVisibleRect
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CapturePhotoResult, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CapturePhotoError.cameraUnavailable)
                    return
                }

                guard self.isConfigured,
                      self.session.isRunning,
                      self.activeZoomTransitionID == nil
                else {
                    continuation.resume(throwing: CapturePhotoError.cameraUnavailable)
                    return
                }

                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = CapturePhotoConfiguration.prioritization(
                    for: self.photoOutput.maxPhotoQualityPrioritization
                )
                let cardRotationAngle = self.cardRotationAngleForCurrentCapture()
                let delegate = PhotoCaptureDelegate(normalizedVisibleRect: requestedVisibleRect) { [weak self] uniqueID in
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

    @MainActor private func configureAndStartSession() {
        state = .loading
        log("configuring")
        let requestedPreparationID = preparationID

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let configured = self.configureSessionIfNeeded()

            guard configured else {
                Task { @MainActor in
                    guard self.preparationID == requestedPreparationID else { return }
                    self.state = .unavailable
                    self.log("config-failed")
                }
                return
            }

            let discoveredPresets = self.configuredZoomPresets
            Task { @MainActor in
                guard self.preparationID == requestedPreparationID else { return }
                self.availableZoomPresets = CameraZoomControlPresentation.visiblePresets(from: discoveredPresets)
            }

            let wasRunning = self.session.isRunning
            let startedAtWide = self.startConfiguredSessionAtWide() ||
                (self.reconfigureForPhysicalWideFallback() && self.startConfiguredSessionAtWide())

            guard startedAtWide else {
                Task { @MainActor in
                    guard self.preparationID == requestedPreparationID else { return }
                    self.state = .unavailable
                    self.availableZoomPresets = []
                    self.log("config-failed")
                }
                return
            }

            let confirmedPresets = self.configuredZoomPresets

            Task { @MainActor in
                guard self.preparationID == requestedPreparationID else { return }
                self.publishRunningState(with: confirmedPresets)
                if wasRunning {
                    self.log("already-running")
                } else {
                    self.log("running inputs=\(self.session.inputs.count) outputs=\(self.session.outputs.count)")
                }
            }
        }
    }

    private func startConfiguredSessionAtWide() -> Bool {
        guard let device = activeCameraDevice,
              let wide = configuredZoomPresets.first(where: { $0.id == .wide })
        else {
            return false
        }

        return CameraStartupZoomCoordinator.startAtWide(
            applyWideBeforeStart: {
                self.resetCamera(device, to: wide.deviceFactor)
            },
            startSession: {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            },
            confirmWideAfterStart: {
                self.resetCamera(device, to: wide.deviceFactor)
            }
        )
    }

    private func reconfigureForPhysicalWideFallback() -> Bool {
        guard activeCameraDevice?.deviceType != .builtInWideAngleCamera,
              let wideDevice = AVCaptureDevice.default(
                  .builtInWideAngleCamera,
                  for: .video,
                  position: .back
              ),
              let wideInput = try? AVCaptureDeviceInput(device: wideDevice)
        else {
            return false
        }

        if session.isRunning {
            session.stopRunning()
        }

        let previousInputs = session.inputs
        session.beginConfiguration()
        previousInputs.forEach(session.removeInput)

        guard session.canAddInput(wideInput) else {
            previousInputs.forEach { input in
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            }
            session.commitConfiguration()
            return false
        }

        session.addInput(wideInput)
        session.commitConfiguration()
        activeCameraDevice = wideDevice
        configuredZoomPresets = [CameraZoomPresetResolver.singleWidePreset]
        return true
    }

    private func configureSessionIfNeeded() -> Bool {
        activeZoomTransitionID = nil
        if isConfigured {
            guard let device = activeCameraDevice,
                  let wide = configuredZoomPresets.first(where: { $0.id == .wide })
            else {
                return false
            }
            return resetCamera(device, to: wide.deviceFactor)
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        var chosenDevice: AVCaptureDevice?
        var chosenInput: AVCaptureDeviceInput?
        var chosenPresets: [CameraZoomPreset] = []

        for device in backCameraCandidates() {
            let presets = zoomPresets(for: device)
            guard let wide = presets.first(where: { $0.id == .wide }),
                  resetCamera(device, to: wide.deviceFactor),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input)
            else {
                logger.warning("Camera candidate unavailable: \(device.localizedName, privacy: .public)")
                continue
            }

            chosenDevice = device
            chosenInput = input
            chosenPresets = presets
            break
        }

        guard let device = chosenDevice, let input = chosenInput else {
            logger.error("No usable back camera device available")
            return false
        }

        logger.info("Using camera device: \(device.localizedName, privacy: .public)")
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            logger.error("Session cannot add photo output")
            session.removeInput(input)
            return false
        }

        session.addOutput(photoOutput)
        activeCameraDevice = device
        configuredZoomPresets = chosenPresets
        isConfigured = true
        return true
    }

    private func backCameraCandidates() -> [AVCaptureDevice] {
        let types: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera
        ]
        var candidates = types.compactMap {
            AVCaptureDevice.default($0, for: .video, position: .back)
        }.prefix(1).map { $0 }
        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           !candidates.contains(where: { $0.uniqueID == wide.uniqueID }) {
            candidates.append(wide)
        }
        return candidates
    }

    private func zoomPresets(for device: AVCaptureDevice) -> [CameraZoomPreset] {
        let minimum = device.minAvailableVideoZoomFactor
        let maximum = device.maxAvailableVideoZoomFactor
        guard minimum.isFinite, maximum.isFinite, minimum > 0, minimum <= maximum else { return [] }

        guard device.isVirtualDevice else {
            return device.deviceType == .builtInWideAngleCamera && minimum <= 1 && maximum >= 1
                ? [CameraZoomPresetResolver.singleWidePreset] : []
        }

        let lenses = device.constituentDevices.compactMap { constituent -> CameraLensKind? in
            switch constituent.deviceType {
            case .builtInUltraWideCamera: .ultraWide
            case .builtInWideAngleCamera: .wide
            case .builtInTelephotoCamera: .telephoto
            default: nil
            }
        }
        guard lenses.count == device.constituentDevices.count else { return [] }

        let switchFactors = device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.doubleValue) }
        guard switchFactors.allSatisfy({ $0.isFinite && $0 > 1 }),
              zip(switchFactors, switchFactors.dropFirst()).allSatisfy({ $0 < $1 })
        else {
            return []
        }

        return CameraZoomPresetResolver.presets(
            lenses: lenses,
            switchOverDeviceFactors: switchFactors,
            availableDeviceRange: minimum...maximum
        )
    }

    private func resetCamera(_ device: AVCaptureDevice, to factor: CGFloat) -> Bool {
        cancelZoomRamp(on: device, resettingTo: factor)
    }

    @discardableResult
    private func cancelZoomRamp(on device: AVCaptureDevice, resettingTo factor: CGFloat? = nil) -> Bool {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.cancelVideoZoomRamp()
            if let factor {
                let minimum = device.minAvailableVideoZoomFactor
                let maximum = device.maxAvailableVideoZoomFactor
                guard factor.isFinite,
                      minimum.isFinite,
                      maximum.isFinite,
                      minimum <= factor,
                      factor <= maximum
                else {
                    return false
                }
                device.videoZoomFactor = factor
                return abs(device.videoZoomFactor - factor) <= zoomTargetTolerance
            }
            return true
        } catch {
            logger.error("Failed to lock camera for zoom cancellation: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    @MainActor private func publishRunningState(with presets: [CameraZoomPreset]) {
        pendingZoomTransitionID = nil
        zoomSelection = CameraZoomSelectionState(selectedPresetID: .wide)
        state = .running
        availableZoomPresets = CameraZoomControlPresentation.visiblePresets(from: presets)
        selectedZoomPresetID = .wide
        isZoomTransitioning = false
    }

    private func startZoomTransition(
        to preset: CameraZoomPreset,
        restoring confirmedPreset: CameraZoomPreset,
        transitionID: UUID
    ) {
        activeZoomTransitionID = transitionID
        guard session.isRunning, let device = activeCameraDevice else {
            restoreConfirmedZoom(
                after: preset,
                to: confirmedPreset,
                transitionID: transitionID
            )
            return
        }

        let minimum = device.minAvailableVideoZoomFactor
        let maximum = device.maxAvailableVideoZoomFactor
        guard minimum.isFinite, maximum.isFinite, minimum > 0, minimum <= maximum else {
            restoreConfirmedZoom(
                after: preset,
                to: confirmedPreset,
                transitionID: transitionID
            )
            return
        }
        let target = min(max(preset.deviceFactor, minimum), maximum)

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.ramp(toVideoZoomFactor: target, withRate: zoomRampRate)
        } catch {
            logger.error("Failed to start camera zoom: \(String(describing: error), privacy: .public)")
            restoreConfirmedZoom(
                after: preset,
                to: confirmedPreset,
                transitionID: transitionID
            )
            return
        }

        pollZoomTransition(
            to: preset,
            restoring: confirmedPreset,
            target: target,
            transitionID: transitionID,
            timeoutAt: .now() + .seconds(4)
        )
    }

    private func pollZoomTransition(
        to preset: CameraZoomPreset,
        restoring confirmedPreset: CameraZoomPreset,
        target: CGFloat,
        transitionID: UUID,
        timeoutAt: DispatchTime
    ) {
        guard activeZoomTransitionID == transitionID else { return }
        guard let device = activeCameraDevice else {
            restoreConfirmedZoom(after: preset, to: confirmedPreset, transitionID: transitionID)
            return
        }
        if device.isRampingVideoZoom {
            if .now() >= timeoutAt {
                restoreConfirmedZoom(after: preset, to: confirmedPreset, transitionID: transitionID)
                return
            }
            sessionQueue.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                self?.pollZoomTransition(
                    to: preset,
                    restoring: confirmedPreset,
                    target: target,
                    transitionID: transitionID,
                    timeoutAt: timeoutAt
                )
            }
            return
        }

        let reachedTarget = abs(device.videoZoomFactor - target) <= zoomTargetTolerance
        if reachedTarget {
            finishZoomTransition(to: preset, transitionID: transitionID, succeeded: true)
        } else {
            restoreConfirmedZoom(after: preset, to: confirmedPreset, transitionID: transitionID)
        }
    }

    private func restoreConfirmedZoom(
        after requestedPreset: CameraZoomPreset,
        to confirmedPreset: CameraZoomPreset,
        transitionID: UUID
    ) {
        guard activeZoomTransitionID == transitionID else { return }
        if let device = activeCameraDevice,
           resetCamera(device, to: confirmedPreset.deviceFactor) {
            finishZoomTransition(to: requestedPreset, transitionID: transitionID, succeeded: false)
            return
        }

        sessionQueue.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
            self?.restoreConfirmedZoom(
                after: requestedPreset,
                to: confirmedPreset,
                transitionID: transitionID
            )
        }
    }

    private func finishZoomTransition(
        to preset: CameraZoomPreset,
        transitionID: UUID,
        succeeded: Bool
    ) {
        guard activeZoomTransitionID == transitionID else { return }
        activeZoomTransitionID = nil
        if !succeeded {
            logger.warning("Camera zoom did not reach \(preset.label, privacy: .public)")
        }

        Task { @MainActor in
            guard self.pendingZoomTransitionID == transitionID else { return }
            self.pendingZoomTransitionID = nil
            self.zoomSelection.completeTransition(for: preset.id, succeeded: succeeded)
            self.selectedZoomPresetID = self.zoomSelection.selectedPresetID
            self.isZoomTransitioning = self.zoomSelection.isTransitioning
        }
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
    nonisolated private let normalizedVisibleRect: CGRect?
    nonisolated(unsafe) private let onFinish: (Int64) -> Void
    nonisolated(unsafe) private let continuation: (Result<UIImage, Error>) -> Void
    nonisolated(unsafe) private var hasResumed = false

    nonisolated init(
        normalizedVisibleRect: CGRect?,
        onFinish: @escaping (Int64) -> Void,
        continuation: @escaping (Result<UIImage, Error>) -> Void
    ) {
        self.normalizedVisibleRect = normalizedVisibleRect
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

        resumeOnce(with: .success(CameraCaptureFraming.crop(image, to: normalizedVisibleRect)))
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
