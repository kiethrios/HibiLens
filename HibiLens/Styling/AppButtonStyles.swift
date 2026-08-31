import SwiftUI

private enum AppButtonMetrics {
    static let primaryMinHeight: CGFloat = 56
    static let secondaryMinHeight: CGFloat = 52
    static let primaryHorizontalPadding: CGFloat = 24
    static let secondaryHorizontalPadding: CGFloat = 20
    static let tertiaryHorizontalPadding: CGFloat = 4
    static let fullCornerRadius: CGFloat = 24
    static let largeCornerRadius: CGFloat = 16
    static let pressedScale: CGFloat = 0.985
    static let pressedOpacity: CGFloat = 0.94
}

struct AppPrimaryButtonStyle: ButtonStyle {
    let theme: AppTheme

    init(theme: AppTheme = AppTheme()) {
        self.theme = theme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.titleMedium)
            .foregroundStyle(theme.buttonPrimaryForeground)
            .padding(.horizontal, AppButtonMetrics.primaryHorizontalPadding)
            .frame(minHeight: AppButtonMetrics.primaryMinHeight)
            .background(
                LinearGradient(
                    colors: [theme.buttonPrimaryGradientStart, theme.buttonPrimaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(
                    cornerRadius: AppButtonMetrics.fullCornerRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? AppButtonMetrics.pressedScale : 1)
            .opacity(configuration.isPressed ? AppButtonMetrics.pressedOpacity : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    let theme: AppTheme

    init(theme: AppTheme = AppTheme()) {
        self.theme = theme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.titleMedium)
            .foregroundStyle(theme.buttonSecondaryForeground)
            .padding(.horizontal, AppButtonMetrics.secondaryHorizontalPadding)
            .frame(minHeight: AppButtonMetrics.secondaryMinHeight)
            .background(
                theme.buttonSecondaryFill,
                in: RoundedRectangle(
                    cornerRadius: AppButtonMetrics.largeCornerRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? AppButtonMetrics.pressedScale : 1)
            .opacity(configuration.isPressed ? AppButtonMetrics.pressedOpacity : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct AppTertiaryButtonStyle: ButtonStyle {
    let theme: AppTheme

    init(theme: AppTheme = AppTheme()) {
        self.theme = theme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.labelMedium.weight(.medium))
            .foregroundStyle(theme.buttonTertiaryForeground)
            .padding(.horizontal, AppButtonMetrics.tertiaryHorizontalPadding)
            .frame(minHeight: AppButtonMetrics.secondaryMinHeight)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? AppButtonMetrics.pressedScale : 1)
            .opacity(configuration.isPressed ? AppButtonMetrics.pressedOpacity : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
