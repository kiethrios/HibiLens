import SwiftUI
import UIKit

/// Maps the portrait control canvas into the current scene without rotating the camera image.
struct CaptureControlGeometry {
    let canvasSize: CGSize
    let insets: EdgeInsets
    let rotationDegrees: Double

    init(size: CGSize, insets: EdgeInsets, orientation: UIInterfaceOrientation) {
        canvasSize = orientation.isLandscape ? CGSize(width: size.height, height: size.width) : size
        switch orientation {
        case .landscapeLeft:
            rotationDegrees = 90
            self.insets = EdgeInsets(top: insets.trailing, leading: insets.top, bottom: insets.leading, trailing: insets.bottom)
        case .landscapeRight:
            rotationDegrees = -90
            self.insets = EdgeInsets(top: insets.leading, leading: insets.bottom, bottom: insets.trailing, trailing: insets.top)
        case .portraitUpsideDown:
            rotationDegrees = 180
            self.insets = EdgeInsets(top: insets.bottom, leading: insets.trailing, bottom: insets.top, trailing: insets.leading)
        default:
            rotationDegrees = 0
            self.insets = insets
        }
    }
}

struct CaptureInterfaceOrientationReader: UIViewControllerRepresentable {
    @Binding var orientation: UIInterfaceOrientation

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.onOrientation = { value in
            if orientation != value { orientation = value }
        }
        controller.publishOrientation()
    }

    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.onOrientation = nil
    }

    final class Controller: UIViewController {
        var onOrientation: ((UIInterfaceOrientation) -> Void)?
        private var lastOrientation: UIInterfaceOrientation?

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            publishOrientation()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            publishOrientation()
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in self?.publishOrientation() }
        }

        func publishOrientation() {
            guard let value = viewIfLoaded?.window?.windowScene?.effectiveGeometry.interfaceOrientation,
                  value != .unknown, value != lastOrientation else { return }
            lastOrientation = value
            DispatchQueue.main.async { [weak self] in self?.onOrientation?(value) }
        }
    }
}
