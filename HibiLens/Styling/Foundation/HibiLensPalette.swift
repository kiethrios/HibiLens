import Foundation

public enum HibiLensPalette {
    public static let background = adaptive(day: (248, 246, 240), dark: (23, 26, 25))
    public static let sectionSurface = adaptive(day: (236, 234, 226), dark: (39, 44, 42))
    public static let cardSurface = adaptive(day: (255, 253, 248), dark: (34, 38, 36))
    public static let raisedCardSurface = adaptive(day: (255, 255, 255), dark: (43, 48, 46))
    public static let primaryText = adaptive(day: (38, 48, 45), dark: (241, 240, 234))
    public static let secondaryText = adaptive(day: (102, 112, 107), dark: (176, 184, 179))
    public static let tertiaryText = adaptive(day: (138, 145, 140), dark: (137, 147, 142))
    public static let contentPrimaryText = adaptive(day: (31, 41, 38), dark: (244, 243, 238))
    public static let primaryAccent = adaptive(day: (47, 93, 80), dark: (143, 179, 166))
    public static let primaryAccentDeep = adaptive(day: (38, 76, 66), dark: (98, 141, 126))
    public static let primaryAccentMuted = adaptive(day: (217, 229, 223), dark: (52, 68, 63))
    public static let secondaryAccent = adaptive(day: (214, 168, 79), dark: (215, 179, 99))
    public static let secondaryAccentMuted = adaptive(day: (243, 228, 192), dark: (74, 64, 42))
    public static let cameraFocus = HibiLensVisualColorToken(red: 255, green: 248, blue: 232)
    public static let success = adaptive(day: (79, 125, 101), dark: (134, 169, 145))
    public static let warning = adaptive(day: (198, 146, 62), dark: (210, 162, 79))
    public static let destructiveMuted = adaptive(day: (184, 90, 84), dark: (215, 123, 115))
    public static let outline = adaptive(day: (173, 179, 176), dark: (101, 112, 107))

    private static func adaptive(
        day: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> HibiLensAdaptiveColorToken {
        HibiLensAdaptiveColorToken(
            day: HibiLensVisualColorToken(red: day.0, green: day.1, blue: day.2),
            dark: HibiLensVisualColorToken(red: dark.0, green: dark.1, blue: dark.2)
        )
    }
}
