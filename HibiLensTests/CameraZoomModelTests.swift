import XCTest
@testable import HibiLens

final class CameraZoomModelTests: XCTestCase {
    func testTripleLensProfileResolvesNativeAndDisplayFactors() {
        let presets = CameraZoomPresetResolver.presets(
            lenses: [.ultraWide, .wide, .telephoto],
            switchOverDeviceFactors: [2, 5],
            availableDeviceRange: 1...5
        )

        XCTAssertEqual(presets.map(\.lens), [.ultraWide, .wide, .telephoto])
        XCTAssertEqual(presets.map(\.deviceFactor), [1, 2, 5])
        XCTAssertEqual(presets.map(\.displayFactor), [0.5, 1, 2.5])
        XCTAssertEqual(presets.map(\.label), ["0.5×", "1×", "2.5×"])
    }

    func testDualWideProfileUsesWideLensAsDisplayBaseline() {
        let presets = CameraZoomPresetResolver.presets(
            lenses: [.ultraWide, .wide],
            switchOverDeviceFactors: [2],
            availableDeviceRange: 1...2
        )

        XCTAssertEqual(presets.map(\.label), ["0.5×", "1×"])
    }

    func testWideAndTelephotoProfileUsesWideLensAsDisplayBaseline() {
        let presets = CameraZoomPresetResolver.presets(
            lenses: [.wide, .telephoto],
            switchOverDeviceFactors: [2.5],
            availableDeviceRange: 1...2.5
        )

        XCTAssertEqual(presets.map(\.label), ["1×", "2.5×"])
    }

    func testSingleWideProfileProducesOnePreset() {
        let presets = CameraZoomPresetResolver.presets(
            lenses: [.wide],
            switchOverDeviceFactors: [],
            availableDeviceRange: 1...1
        )

        XCTAssertEqual(presets.map(\.label), ["1×"])
    }

    func testMismatchedSwitchFactorsRejectProfile() {
        XCTAssertTrue(CameraZoomPresetResolver.presets(
            lenses: [.ultraWide, .wide, .telephoto],
            switchOverDeviceFactors: [2],
            availableDeviceRange: 1...5
        ).isEmpty)
    }

    func testUnavailableTelephotoIsFilteredFromProfile() {
        let presets = CameraZoomPresetResolver.presets(
            lenses: [.ultraWide, .wide, .telephoto],
            switchOverDeviceFactors: [2, 5],
            availableDeviceRange: 1...2
        )

        XCTAssertEqual(presets.map(\.lens), [.ultraWide, .wide])
        XCTAssertEqual(presets.map(\.label), ["0.5×", "1×"])
    }

    func testUnavailableWideRejectsWholeProfile() {
        XCTAssertTrue(CameraZoomPresetResolver.presets(
            lenses: [.ultraWide, .wide, .telephoto],
            switchOverDeviceFactors: [2, 5],
            availableDeviceRange: 1...1
        ).isEmpty)
    }

    func testEmptyLensProfileIsRejected() {
        XCTAssertTrue(CameraZoomPresetResolver.presets(
            lenses: [],
            switchOverDeviceFactors: [],
            availableDeviceRange: 1...5
        ).isEmpty)
    }

    func testDuplicateLensProfileIsRejected() {
        XCTAssertTrue(CameraZoomPresetResolver.presets(
            lenses: [.wide, .wide],
            switchOverDeviceFactors: [2],
            availableDeviceRange: 1...2
        ).isEmpty)
    }

    func testIncorrectlyOrderedLensProfileIsRejected() {
        XCTAssertTrue(CameraZoomPresetResolver.presets(
            lenses: [.wide, .ultraWide],
            switchOverDeviceFactors: [2],
            availableDeviceRange: 1...2
        ).isEmpty)
    }

    func testNonFiniteSwitchPositionsAreFiltered() {
        let infiniteFactorPresets = CameraZoomPresetResolver.presets(
            lenses: [.wide, .telephoto],
            switchOverDeviceFactors: [.infinity],
            availableDeviceRange: 1...5
        )
        let nanFactorPresets = CameraZoomPresetResolver.presets(
            lenses: [.wide, .telephoto],
            switchOverDeviceFactors: [.nan],
            availableDeviceRange: 1...5
        )
        XCTAssertEqual(infiniteFactorPresets.map(\.lens), [.wide])
        XCTAssertEqual(nanFactorPresets.map(\.lens), [.wide])
    }

    func testNonpositiveSwitchPositionsAreFiltered() {
        let zeroFactorPresets = CameraZoomPresetResolver.presets(
            lenses: [.wide, .telephoto],
            switchOverDeviceFactors: [0],
            availableDeviceRange: 0...5
        )
        let negativeFactorPresets = CameraZoomPresetResolver.presets(
            lenses: [.wide, .telephoto],
            switchOverDeviceFactors: [-2],
            availableDeviceRange: -2...5
        )
        XCTAssertEqual(zeroFactorPresets.map(\.lens), [.wide])
        XCTAssertEqual(negativeFactorPresets.map(\.lens), [.wide])
    }

    func testSelectionSerializesRequestsAndCompletesSuccessfulTransition() {
        var state = CameraZoomSelectionState(selectedPresetID: .wide)

        XCTAssertEqual(state.selectedPresetID, .wide)
        XCTAssertTrue(state.beginTransition(to: .telephoto))
        XCTAssertTrue(state.isTransitioning)
        XCTAssertFalse(state.beginTransition(to: .ultraWide))
        XCTAssertFalse(state.beginTransition(to: .wide))
        XCTAssertEqual(state.pendingPresetID, .telephoto)

        state.completeTransition(for: .telephoto, succeeded: true)

        XCTAssertEqual(state.selectedPresetID, .telephoto)
        XCTAssertNil(state.pendingPresetID)
        XCTAssertFalse(state.isTransitioning)
    }

    func testFailedTransitionRetainsSelection() {
        var state = CameraZoomSelectionState(selectedPresetID: .wide)
        XCTAssertTrue(state.beginTransition(to: .telephoto))

        state.completeTransition(for: .telephoto, succeeded: false)

        XCTAssertEqual(state.selectedPresetID, .wide)
        XCTAssertNil(state.pendingPresetID)
    }

    func testCanceledTransitionAllowsAnotherRequest() {
        var state = CameraZoomSelectionState(selectedPresetID: .wide)
        XCTAssertTrue(state.beginTransition(to: .telephoto))

        state.cancelTransition()

        XCTAssertNil(state.pendingPresetID)
        XCTAssertTrue(state.beginTransition(to: .ultraWide))
    }

    func testMismatchedCompletionCallbackLeavesCurrentTransitionPending() {
        var state = CameraZoomSelectionState(selectedPresetID: .wide)
        XCTAssertTrue(state.beginTransition(to: .telephoto))

        state.completeTransition(for: .ultraWide, succeeded: true)

        XCTAssertEqual(state.selectedPresetID, .wide)
        XCTAssertEqual(state.pendingPresetID, .telephoto)
        XCTAssertTrue(state.isTransitioning)
    }

    func testSingleWidePresetHasExactValues() {
        XCTAssertEqual(CameraZoomPresetResolver.singleWidePreset, CameraZoomPreset(
            lens: .wide,
            displayFactor: 1,
            deviceFactor: 1
        ))
    }

    func testCameraStartupAppliesWideBeforeStartAndConfirmsItAfterStart() {
        var operations: [String] = []

        let succeeded = CameraStartupZoomCoordinator.startAtWide(
            applyWideBeforeStart: {
                operations.append("apply-before-start")
                return true
            },
            startSession: {
                operations.append("start-session")
            },
            confirmWideAfterStart: {
                operations.append("confirm-after-start")
                return true
            }
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(
            operations,
            ["apply-before-start", "start-session", "confirm-after-start"]
        )
    }

    func testCameraStartupDoesNotStartWhenPreflightWideResetFails() {
        var didStart = false

        let succeeded = CameraStartupZoomCoordinator.startAtWide(
            applyWideBeforeStart: { false },
            startSession: { didStart = true },
            confirmWideAfterStart: { true }
        )

        XCTAssertFalse(succeeded)
        XCTAssertFalse(didStart)
    }

    func testCameraStartupRejectsUnconfirmedWideFactorAfterStart() {
        let succeeded = CameraStartupZoomCoordinator.startAtWide(
            applyWideBeforeStart: { true },
            startSession: {},
            confirmWideAfterStart: { false }
        )

        XCTAssertFalse(succeeded)
    }

    func testZoomControlsRequireMoreThanOneLensPosition() {
        let wide = CameraZoomPresetResolver.singleWidePreset
        let ultraWide = CameraZoomPreset(lens: .ultraWide, displayFactor: 0.5, deviceFactor: 1)

        XCTAssertEqual(CameraZoomControlPresentation.visiblePresets(from: [wide]), [])
        XCTAssertEqual(
            CameraZoomControlPresentation.visiblePresets(from: [ultraWide, wide]),
            [ultraWide, wide]
        )
    }
}
