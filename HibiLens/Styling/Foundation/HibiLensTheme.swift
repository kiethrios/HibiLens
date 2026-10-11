import SwiftUI

public enum HibiLensSurfaceDepth: CaseIterable, Equatable {
    case base
    case section
    case card
    case elevated
}

/// The exhaustive Stage 1 semantic theme contract for this repository-local,
/// unversioned package.
///
/// Capability splitting is deferred until a second concrete theme demonstrates
/// a stable smaller boundary.
@MainActor
public protocol HibiLensTheme {
    var background: Color { get }
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }
    var contentPrimaryText: Color { get }

    var surfaceBase: Color { get }
    var surfaceSecondarySection: Color { get }
    var surfaceInteractiveCard: Color { get }
    var surfaceInteractiveCardEmphasis: Color { get }
    var surfaceInteractiveHighest: Color { get }
    var surfaceImagePlaceholder: Color { get }
    var surfaceInteractiveControl: Color { get }
    var surfaceHighEmphasis: Color { get }

    var accentPrimaryStrong: Color { get }
    var accentPrimaryGradientEnd: Color { get }
    var accentPrimarySoft: Color { get }
    var accentSupportStrong: Color { get }
    var accentSupportMuted: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var destructiveMuted: Color { get }
    var outlineVariant: Color { get }

    var glassShellTint: Color { get }
    var activeNavigationGlassTint: Color { get }
    var inactiveNavigationGlassTint: Color { get }

    var cameraPreviewBase: Color { get }
    var cameraPreviewScrim: Color { get }
    var cameraControlSurface: Color { get }
    var cameraControlForeground: Color { get }
    var cameraGuidanceStroke: Color { get }
    var cameraGuidanceAccent: Color { get }
    var cameraShutterOuterSurface: Color { get }
    var cameraShutterInnerSurface: Color { get }
    var cameraShutterCore: Color { get }
    var cameraMessageSurface: Color { get }
    var cameraMessagePrimaryText: Color { get }
    var cameraMessageSecondaryText: Color { get }

    var buttonPrimaryGradientStart: Color { get }
    var buttonPrimaryGradientEnd: Color { get }
    var buttonPrimaryForeground: Color { get }
    var buttonSecondaryFill: Color { get }
    var buttonSecondaryForeground: Color { get }
    var buttonTertiaryForeground: Color { get }
    var inputFill: Color { get }
    var inputFocusedFill: Color { get }
    var inputForeground: Color { get }
    var inputPlaceholder: Color { get }
    var inputHelperText: Color { get }

    var usesExplicitDividersByDefault: Bool { get }
    var prefersTonalLayeringOverShadows: Bool { get }
    var allowsStandardIOSShadows: Bool { get }
    var ambientShadowTint: Color { get }
    var ambientShadowRadius: CGFloat { get }
    var ambientShadowYOffset: CGFloat { get }

    func surfaceColor(for depth: HibiLensSurfaceDepth) -> Color
    func shouldUseAmbientShadow(for depth: HibiLensSurfaceDepth) -> Bool
}
