import SwiftUI

private struct HibiLensRoundedSurfaceModifier: ViewModifier {
    let fill: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(
            fill,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
}

private struct HibiLensCircularSurfaceModifier: ViewModifier {
    let fill: Color

    func body(content: Content) -> some View {
        content.background(fill, in: Circle())
    }
}

private struct HibiLensAmbientDepthModifier<Theme: HibiLensTheme>: ViewModifier {
    let theme: Theme
    let depth: HibiLensSurfaceDepth
    let yOffset: CGFloat?

    func body(content: Content) -> some View {
        if theme.shouldUseAmbientShadow(for: depth) {
            content.shadow(
                color: theme.ambientShadowTint,
                radius: theme.ambientShadowRadius,
                x: 0,
                y: yOffset ?? theme.ambientShadowYOffset
            )
        } else {
            content
        }
    }
}

public extension View {
    func foundationRoundedSurface(fill: Color, cornerRadius: CGFloat) -> some View {
        modifier(HibiLensRoundedSurfaceModifier(fill: fill, cornerRadius: cornerRadius))
    }

    func foundationCircularSurface(fill: Color) -> some View {
        modifier(HibiLensCircularSurfaceModifier(fill: fill))
    }

    func foundationAmbientDepth<Theme: HibiLensTheme>(
        theme: Theme,
        depth: HibiLensSurfaceDepth,
        yOffset: CGFloat? = nil
    ) -> some View {
        modifier(HibiLensAmbientDepthModifier(theme: theme, depth: depth, yOffset: yOffset))
    }

    func foundationCardSurface<Theme: HibiLensTheme>(
        theme: Theme,
        depth: HibiLensSurfaceDepth,
        fill: Color,
        cornerRadius: CGFloat
    ) -> some View {
        background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .foundationAmbientDepth(theme: theme, depth: depth)
    }
}
