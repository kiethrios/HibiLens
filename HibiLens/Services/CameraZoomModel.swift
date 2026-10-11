import Foundation

enum CameraLensKind: String, Hashable, Sendable {
    case ultraWide
    case wide
    case telephoto
}

struct CameraZoomPreset: Identifiable, Equatable, Sendable {
    let lens: CameraLensKind
    let displayFactor: CGFloat
    let deviceFactor: CGFloat

    var id: CameraLensKind { lens }

    var label: String {
        let rounded = (displayFactor * 10).rounded() / 10
        let number = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), Double(rounded))
        let formatted = number.hasSuffix(".0") ? String(number.dropLast(2)) : number
        return "\(formatted)×"
    }
}

enum CameraZoomPresetResolver {
    static let singleWidePreset = CameraZoomPreset(
        lens: .wide,
        displayFactor: 1,
        deviceFactor: 1
    )

    static func presets(
        lenses: [CameraLensKind],
        switchOverDeviceFactors: [CGFloat],
        availableDeviceRange: ClosedRange<CGFloat>
    ) -> [CameraZoomPreset] {
        // Lens order must follow the camera's ultra-wide to telephoto progression.
        guard !lenses.isEmpty,
              switchOverDeviceFactors.count == lenses.count - 1,
              let wideIndex = lenses.firstIndex(of: .wide),
              zip(lenses, lenses.dropFirst()).allSatisfy({ rank(of: $0) < rank(of: $1) })
        else {
            return []
        }

        let deviceFactors = [CGFloat(1)] + switchOverDeviceFactors
        let wideFactor = deviceFactors[wideIndex]
        guard wideFactor.isFinite, wideFactor > 0 else { return [] }

        let resolved = zip(lenses, deviceFactors).compactMap { lens, deviceFactor -> CameraZoomPreset? in
            guard deviceFactor.isFinite,
                  deviceFactor > 0,
                  availableDeviceRange.contains(deviceFactor)
            else {
                return nil
            }

            let displayFactor = deviceFactor / wideFactor
            guard displayFactor.isFinite, displayFactor > 0 else { return nil }
            return CameraZoomPreset(lens: lens, displayFactor: displayFactor, deviceFactor: deviceFactor)
        }

        guard resolved.contains(where: { $0.lens == .wide }) else { return [] }
        return resolved
    }

    private static func rank(of lens: CameraLensKind) -> Int {
        switch lens {
        case .ultraWide: return 0
        case .wide: return 1
        case .telephoto: return 2
        }
    }
}

struct CameraZoomSelectionState: Equatable, Sendable {
    private(set) var selectedPresetID: CameraLensKind
    private(set) var pendingPresetID: CameraLensKind?

    init(selectedPresetID: CameraLensKind) {
        self.selectedPresetID = selectedPresetID
        pendingPresetID = nil
    }

    var isTransitioning: Bool { pendingPresetID != nil }

    @discardableResult
    mutating func beginTransition(to presetID: CameraLensKind) -> Bool {
        guard pendingPresetID == nil, presetID != selectedPresetID else { return false }
        pendingPresetID = presetID
        return true
    }

    mutating func completeTransition(for presetID: CameraLensKind, succeeded: Bool) {
        guard pendingPresetID == presetID else { return }
        if succeeded {
            selectedPresetID = presetID
        }
        pendingPresetID = nil
    }

    mutating func cancelTransition() {
        pendingPresetID = nil
    }
}
