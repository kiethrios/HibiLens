import SwiftUI

private struct AppKeepsakeCardSurfaceModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(theme.keepsakeCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .foundationAmbientDepth(theme: theme, depth: .elevated, yOffset: 10)
    }
}

private struct AppSubjectStageSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

private struct AppGlassSurfaceModifier: ViewModifier {
    let fill: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                fill,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

private struct AppViewfinderCornersModifier: ViewModifier {
    let theme: AppTheme
    let length: CGFloat
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { geometry in
                let size = CGSize(width: length, height: length)

                ZStack {
                    CornerBracketShape(alignment: .topLeading)
                        .stroke(theme.cameraFocus.opacity(0.86), lineWidth: lineWidth)
                        .frame(width: size.width, height: size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    CornerBracketShape(alignment: .topTrailing)
                        .stroke(theme.cameraFocus.opacity(0.86), lineWidth: lineWidth)
                        .frame(width: size.width, height: size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    CornerBracketShape(alignment: .bottomLeading)
                        .stroke(theme.cameraFocus.opacity(0.86), lineWidth: lineWidth)
                        .frame(width: size.width, height: size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                    CornerBracketShape(alignment: .bottomTrailing)
                        .stroke(theme.cameraFocus.opacity(0.86), lineWidth: lineWidth)
                        .frame(width: size.width, height: size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func appKeepsakeCardSurface(
        theme: AppTheme,
        cornerRadius: CGFloat = AppLayout.keepsakeCardCornerRadius
    ) -> some View {
        modifier(
            AppKeepsakeCardSurfaceModifier(
                theme: theme,
                cornerRadius: cornerRadius
            )
        )
    }

    func appSubjectStageSurface(theme _: AppTheme) -> some View {
        modifier(AppSubjectStageSurfaceModifier())
    }

    func appCameraGlassSurface(
        theme: AppTheme,
        cornerRadius: CGFloat = AppLayout.glassControlCornerRadius
    ) -> some View {
        modifier(
            AppGlassSurfaceModifier(
                fill: theme.glassShellTint,
                cornerRadius: cornerRadius
            )
        )
    }

    func appNavigationGlassSurface(
        theme: AppTheme,
        cornerRadius: CGFloat = AppLayout.pillCornerRadius
    ) -> some View {
        modifier(
            AppGlassSurfaceModifier(
                fill: theme.activeNavGlassTint,
                cornerRadius: cornerRadius
            )
        )
    }

    func appViewfinderCorners(
        theme: AppTheme,
        length: CGFloat = 26,
        lineWidth: CGFloat = 1.5
    ) -> some View {
        modifier(
            AppViewfinderCornersModifier(
                theme: theme,
                length: length,
                lineWidth: lineWidth
            )
        )
    }

    func appCardSurface(
        theme: AppTheme,
        depth: AppTheme.SurfaceDepth,
        fill: Color,
        cornerRadius: CGFloat
    ) -> some View {
        foundationCardSurface(
            theme: theme,
            depth: depth.foundationDepth,
            fill: fill,
            cornerRadius: cornerRadius
        )
    }

    func appPlaceholderSurface(fill: Color, cornerRadius: CGFloat) -> some View {
        foundationRoundedSurface(fill: fill, cornerRadius: cornerRadius)
    }

    func appCircularGlassControl(fill: Color) -> some View {
        foundationCircularSurface(fill: fill)
    }

    func appAmbientDepth(
        theme: AppTheme,
        depth: AppTheme.SurfaceDepth,
        yOffset: CGFloat? = nil
    ) -> some View {
        foundationAmbientDepth(theme: theme, depth: depth.foundationDepth, yOffset: yOffset)
    }
}
