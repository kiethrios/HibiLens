import SwiftUI

struct AppMotionToken: Equatable {
    let duration: TimeInterval
}

enum AppMotion {
    static let focusLock = AppMotionToken(duration: 0.22)
    static let focusPulse = AppMotionToken(duration: 0.9)
    static let subjectLift = AppMotionToken(duration: 0.58)
    static let cardSettle = AppMotionToken(duration: 0.42)
    static let detailExpand = AppMotionToken(duration: 0.42)
    static let detailDismiss = AppMotionToken(duration: 0.32)
    static let discoveryHighlight = AppMotionToken(duration: 1.1)
    static let reviewInteraction = AppMotionToken(duration: 0.16)
    static let rootNavigation = AppMotionToken(duration: 0.30)

    static var focusLockAnimation: Animation {
        .easeOut(duration: focusLock.duration)
    }

    static var focusPulseAnimation: Animation {
        .easeInOut(duration: focusPulse.duration).repeatForever(autoreverses: true)
    }

    static var subjectLiftAnimation: Animation {
        .spring(response: subjectLift.duration, dampingFraction: 0.86)
    }

    static var cardSettleAnimation: Animation {
        .spring(response: cardSettle.duration, dampingFraction: 0.88)
    }

    static var detailExpandAnimation: Animation {
        .spring(response: detailExpand.duration, dampingFraction: 0.88)
    }

    static var detailDismissAnimation: Animation {
        .easeOut(duration: detailDismiss.duration)
    }

    static var discoveryHighlightAnimation: Animation {
        .easeInOut(duration: discoveryHighlight.duration)
    }

    static var reviewInteractionAnimation: Animation {
        .easeOut(duration: reviewInteraction.duration)
    }

    static var rootNavigationAnimation: Animation {
        .easeInOut(duration: rootNavigation.duration)
    }
}
