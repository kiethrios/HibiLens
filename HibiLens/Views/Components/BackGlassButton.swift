import SwiftUI

struct BackGlassButton: View {
    private let theme = AppTheme()
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(theme.cameraControlForeground)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .appCircularGlassControl(fill: theme.cameraControlSurface)
        .accessibilityLabel(AppL10n.Accessibility.back)
    }
}

#Preview {
    ZStack {
        AppTheme().cameraPreviewBase.opacity(0.2).ignoresSafeArea()
        BackGlassButton(action: { })
    }
}
