import SwiftUI

struct BottomNavBar: View {
    private let theme = AppTheme()
    private let visibleDestinations = NavDestination.allCases.filter { $0 != .capture }

    @Binding var activeDestination: NavDestination
    let onSelect: (NavDestination) -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(visibleDestinations) { destination in
                            navButton(destination)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(theme.glassShellTint), in: .capsule)
            } else {
                HStack(spacing: 0) {
                    ForEach(visibleDestinations) { destination in
                        navButton(destination)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(theme.surfaceBase.opacity(0.7))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                )
            }
        }
        .frame(height: AppLayout.bottomNavBarHeight)
        .appAmbientDepth(theme: theme, depth: .elevated, yOffset: -8)
    }

    private func navButton(_ destination: NavDestination) -> some View {
        let isActive = activeDestination == destination

        return Button {
            onSelect(destination)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: destination.symbol)
                    .font(
                        destination == .review
                        ? AppTypography.headlineMedium.weight(isActive ? .medium : .regular)
                        : AppTypography.titleLarge.weight(isActive ? .medium : .regular)
                    )

                Text(destination.title)
                    .font(AppTypography.labelXSmall.weight(isActive ? .medium : .regular))
                    .tracking(AppTypography.labelTracking)
                    .textCase(.uppercase)
            }
            .foregroundStyle(isActive ? theme.primaryText : theme.navigationInactiveText)
            .frame(width: 106)
            .frame(maxHeight: .infinity)
            .contentShape(Capsule())
            .modifier(NavGlassEffect(theme: theme, isActive: isActive))
        }
        .buttonStyle(.plain)
    }
}

private struct NavGlassEffect: ViewModifier {
    let theme: AppTheme
    let isActive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isActive {
                content
                    .glassEffect(
                        .regular.tint(theme.activeNavGlassTint).interactive(),
                        in: .capsule
                    )
            } else {
                content
                    .padding(.vertical, 2)
            }
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? theme.surfaceInteractiveControl : .clear)
                )
        }
    }
}

#Preview {
    @Previewable @State var activeDestination: NavDestination = .home

    BottomNavBar(activeDestination: $activeDestination) { destination in
        activeDestination = destination
    }
}
