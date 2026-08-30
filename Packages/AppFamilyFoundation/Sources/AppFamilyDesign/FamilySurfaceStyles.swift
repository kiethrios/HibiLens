import SwiftUI

private struct FamilyRoundedSurfaceModifier: ViewModifier {
    let fill: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(
            fill,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
}

private struct FamilyCircularSurfaceModifier: ViewModifier {
    let fill: Color

    func body(content: Content) -> some View {
        content.background(fill, in: Circle())
    }
}

private struct FamilyAmbientDepthModifier<Theme: FamilyTheme>: ViewModifier {
    let theme: Theme
    let depth: FamilySurfaceDepth
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
    func familyRoundedSurface(fill: Color, cornerRadius: CGFloat) -> some View {
        modifier(FamilyRoundedSurfaceModifier(fill: fill, cornerRadius: cornerRadius))
    }

    func familyCircularSurface(fill: Color) -> some View {
        modifier(FamilyCircularSurfaceModifier(fill: fill))
    }

    func familyAmbientDepth<Theme: FamilyTheme>(
        theme: Theme,
        depth: FamilySurfaceDepth,
        yOffset: CGFloat? = nil
    ) -> some View {
        modifier(FamilyAmbientDepthModifier(theme: theme, depth: depth, yOffset: yOffset))
    }

    func familyCardSurface<Theme: FamilyTheme>(
        theme: Theme,
        depth: FamilySurfaceDepth,
        fill: Color,
        cornerRadius: CGFloat
    ) -> some View {
        background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .familyAmbientDepth(theme: theme, depth: depth)
    }
}
