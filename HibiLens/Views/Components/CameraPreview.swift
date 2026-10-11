//
//  CameraPreview.swift
//  HibiLens
//

@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var normalizedVisibleRect: CGRect?

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $normalizedVisibleRect)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        let coordinator = context.coordinator
        view.onVisibleRectChange = { [weak coordinator] rect in
            coordinator?.publish(rect)
        }
        view.setSession(session)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.binding = $normalizedVisibleRect
        uiView.setSession(session)
        uiView.reportVisibleRect()
    }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        uiView.onVisibleRectChange = nil
        uiView.setSession(nil)
        coordinator.invalidate()
    }

    final class Coordinator {
        var binding: Binding<CGRect?>
        private var pendingRect: CGRect?
        private var hasPendingRect = false
        private var isActive = true

        init(binding: Binding<CGRect?>) {
            self.binding = binding
        }

        func publish(_ rect: CGRect?) {
            guard isActive else { return }
            if hasPendingRect {
                guard pendingRect != rect else { return }
                pendingRect = rect
                return
            }
            guard binding.wrappedValue != rect else { return }
            pendingRect = rect
            hasPendingRect = true
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isActive else { return }
                self.hasPendingRect = false
                if self.binding.wrappedValue != self.pendingRect {
                    self.binding.wrappedValue = self.pendingRect
                }
            }
        }

        func invalidate() {
            isActive = false
            pendingRect = nil
            hasPendingRect = false
        }
    }
}

final class PreviewView: UIView {
    var onVisibleRectChange: ((CGRect?) -> Void)?
    private var observedSession: AVCaptureSession?
    private var sessionObservers: [NSObjectProtocol] = []

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reportVisibleRect()
    }

    func setSession(_ session: AVCaptureSession?) {
        guard observedSession !== session else { return }
        sessionObservers.forEach(NotificationCenter.default.removeObserver)
        sessionObservers.removeAll()
        observedSession = session
        previewLayer.session = session

        if let session {
            for name in [AVCaptureSession.didStartRunningNotification, AVCaptureSession.didStopRunningNotification] {
                let observer = NotificationCenter.default.addObserver(
                    forName: name,
                    object: session,
                    queue: .main
                ) { [weak self] _ in
                    self?.reportVisibleRect()
                }
                sessionObservers.append(observer)
            }
        }
        reportVisibleRect()
    }

    func reportVisibleRect() {
        guard let session = previewLayer.session,
              session.isRunning,
              previewLayer.connection != nil,
              bounds.width.isFinite, bounds.height.isFinite,
              bounds.width > 0, bounds.height > 0
        else {
            onVisibleRectChange?(nil)
            return
        }

        let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: bounds).standardized
        let unitBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
        guard [rect.origin.x, rect.origin.y, rect.width, rect.height].allSatisfy(\.isFinite),
              !rect.isEmpty,
              rect.intersects(unitBounds)
        else {
            onVisibleRectChange?(nil)
            return
        }
        onVisibleRectChange?(rect)
    }

    deinit {
        sessionObservers.forEach(NotificationCenter.default.removeObserver)
    }
}
