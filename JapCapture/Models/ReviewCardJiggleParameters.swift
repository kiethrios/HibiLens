//
//  ReviewCardJiggleParameters.swift
//  JapCapture
//
//  Created by Codex on 2026/5/20.
//

import Foundation

struct ReviewCardJiggleParameters: Equatable {
    let angleDegrees: Double
    let duration: TimeInterval
    let delay: TimeInterval

    static func forCard(id: UUID) -> ReviewCardJiggleParameters {
        let seed = id.uuidString.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult &* 31 &+ Int(scalar.value)
        }

        return ReviewCardJiggleParameters(
            angleDegrees: 0.9 + Double(seed % 7) * 0.08,
            duration: 0.11 + Double((seed / 7) % 5) * 0.012,
            delay: Double((seed / 31) % 6) * 0.025
        )
    }
}
