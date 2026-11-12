import SwiftUI
import UIKit

/// Gives the navigation stack first refusal on edge swipes inside the card pager.
struct VocabularyPagerBackGesturePriority: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController {
        private weak var configuredPagerPan: UIPanGestureRecognizer?
        private weak var configuredEdgeBack: UIGestureRecognizer?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            prioritizeEdgeBack()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            prioritizeEdgeBack()
        }

        private func prioritizeEdgeBack() {
            guard let edgeBack = navigationController?.interactivePopGestureRecognizer else { return }

            var ancestor = view.superview
            while let current = ancestor {
                if let scrollView = current as? UIScrollView, scrollView.isPagingEnabled {
                    let pagerPan = scrollView.panGestureRecognizer
                    guard configuredPagerPan !== pagerPan || configuredEdgeBack !== edgeBack else { return }

                    pagerPan.require(toFail: edgeBack)
                    configuredPagerPan = pagerPan
                    configuredEdgeBack = edgeBack
                    return
                }
                ancestor = current.superview
            }
        }
    }
}
