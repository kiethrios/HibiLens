import SwiftUI
import UIKit

/// An RGBA color token with RGB components expressed in 8-bit component units.
///
/// Callers supply RGB values in `0...255` and opacity in `0...1`. Values are
/// stored unchanged so the token preserves the caller's exact inputs.
public struct FamilyVisualColorToken: Equatable {
    /// The red component in 8-bit component units, supplied in `0...255`.
    public let red: Double

    /// The green component in 8-bit component units, supplied in `0...255`.
    public let green: Double

    /// The blue component in 8-bit component units, supplied in `0...255`.
    public let blue: Double

    /// The alpha component, supplied in `0...1`.
    public let opacity: Double

    /// Creates a color token while preserving the supplied component values.
    ///
    /// - Parameters:
    ///   - red: Red in 8-bit component units, supplied in `0...255`.
    ///   - green: Green in 8-bit component units, supplied in `0...255`.
    ///   - blue: Blue in 8-bit component units, supplied in `0...255`.
    ///   - opacity: Alpha supplied in `0...1`. The default is `1`.
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    public var color: Color { Color(uiColor: uiColor) }

    public var uiColor: UIColor {
        UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: opacity
        )
    }

    public var relativeLuminance: Double {
        let r = Self.linearized(red / 255)
        let g = Self.linearized(green / 255)
        let b = Self.linearized(blue / 255)
        return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    }

    public func contrastRatio(with other: FamilyVisualColorToken) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    public var hexRGB: String {
        String(
            format: "#%02X%02X%02X",
            Int(red.rounded()),
            Int(green.rounded()),
            Int(blue.rounded())
        )
    }

    private static func linearized(_ component: Double) -> Double {
        component <= 0.04045
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}

public struct FamilyAdaptiveColorToken: Equatable {
    public let day: FamilyVisualColorToken
    public let dark: FamilyVisualColorToken

    public init(day: FamilyVisualColorToken, dark: FamilyVisualColorToken) {
        self.day = day
        self.dark = dark
    }

    public var color: Color { Color(uiColor: uiColor) }

    public var uiColor: UIColor {
        UIColor { traits in value(for: traits.userInterfaceStyle).uiColor }
    }

    public func value(for interfaceStyle: UIUserInterfaceStyle) -> FamilyVisualColorToken {
        interfaceStyle == .dark ? dark : day
    }
}
