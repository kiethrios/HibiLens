import SwiftUI

struct PronunciationButton: View {
    private let theme = AppTheme()

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "waveform")
                .font(AppTypography.displayMedium.weight(.medium))
                .foregroundStyle(theme.primaryText)
                .frame(width: 72, height: 72)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppL10n.Accessibility.playPronunciation)
    }
}
