import UIKit

struct AppTabBarPalette {
    let surface: UIColor
    let selectedForeground: UIColor
    let selectedFill: UIColor
    let inactiveForeground: UIColor

    static let hibiLens = AppTabBarPalette(
        surface: UIColor { traits in
            let token = traits.userInterfaceStyle == .dark
                ? AppColorToken.galleryBand.dark
                : AppColorToken.galleryBackground.day
            return token.uiColor.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.88 : 0.82)
        },
        selectedForeground: AppColorToken.lensAccent.uiColor,
        selectedFill: UIColor { traits in
            let token = AppColorToken.lensMuted.value(for: traits.userInterfaceStyle)
            return token.uiColor.withAlphaComponent(0.72)
        },
        inactiveForeground: AppColorToken.navigationInactive.uiColor
    )
}

@MainActor
enum AppTabBarAppearance {
    static func make(palette: AppTabBarPalette) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = palette.surface
        appearance.selectionIndicatorTintColor = palette.selectedFill

        configure(appearance.stackedLayoutAppearance, palette: palette)
        configure(appearance.inlineLayoutAppearance, palette: palette)
        configure(appearance.compactInlineLayoutAppearance, palette: palette)
        return appearance
    }

    static func apply() {
        apply(palette: .hibiLens)
    }

    static func apply(palette: AppTabBarPalette) {
        let appearance = make(palette: palette)
        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.tintColor = palette.selectedForeground
        proxy.unselectedItemTintColor = palette.inactiveForeground
    }

    static func apply(palette: AppTabBarPalette, to tabBar: UITabBar) {
        let appearance = make(palette: palette)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = palette.selectedForeground
        tabBar.unselectedItemTintColor = palette.inactiveForeground
    }

    private static func configure(_ itemAppearance: UITabBarItemAppearance, palette: AppTabBarPalette) {
        itemAppearance.normal.iconColor = palette.inactiveForeground
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: palette.inactiveForeground]
        itemAppearance.selected.iconColor = palette.selectedForeground
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: palette.selectedForeground]
    }
}
