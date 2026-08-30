//
//  ReviewDeleteModeDismissal.swift
//  JapCapture
//
//  Created by Codex on 2026/5/20.
//

enum ReviewDeleteModeDismissal {
    enum TapTarget {
        case background
        case segmentedControl
        case card
        case deleteButton
    }

    static func shouldDismiss(isDeleteModeActive: Bool, target: TapTarget) -> Bool {
        guard isDeleteModeActive else { return false }

        switch target {
        case .background, .segmentedControl:
            return true
        case .card, .deleteButton:
            return false
        }
    }
}
