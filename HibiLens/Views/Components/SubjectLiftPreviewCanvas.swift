import SwiftUI

struct SubjectLiftPreviewCanvas: View {
    let preview: SubjectLiftPreview
    let phase: SubjectLiftAnimationPhase
    let orbitRotation: Angle

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                fullScreenPreview(in: geometry)

                fullScreenLiftedSubject(in: geometry)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fullScreenPreview(in geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            Image(uiImage: preview.originalImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .opacity(phase.originalPhotoOpacity)

            Color.black
                .opacity(1 - phase.backgroundOpacity)
        }
    }

    private func fullScreenLiftedSubject(in geometry: GeometryProxy) -> some View {
        let viewport = phase == .glowOnOriginal ? geometry.size : CGSize(
            width: geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing,
            height: geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
        )
        let imageSize = SubjectLiftPreviewSizing.imageSize(
            image: preview.fullFrameImage.size,
            viewport: viewport,
            showsOriginal: phase == .glowOnOriginal
        )
        return ZStack {
            Image(uiImage: preview.fullFrameImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .frame(width: imageSize.width, height: imageSize.height)
                .opacity(phase.staticGlowOpacity * 0.55)
                .blur(radius: 3)
                .scaleEffect(1.01)

            if phase.showsOrbitingGlow {
                AngularGradient(
                    colors: [
                        .clear,
                        .clear,
                        .white.opacity(0.18),
                        .mint.opacity(0.45),
                        .white.opacity(0.92),
                        .cyan.opacity(0.35),
                        .clear
                    ],
                    center: .center
                )
                .rotationEffect(orbitRotation)
                .mask(
                    Image(uiImage: preview.fullFrameImage)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: imageSize.width, height: imageSize.height)
                        .blur(radius: 1.4)
                        .scaleEffect(1.008)
                )
                .blur(radius: 1)
                .transition(.opacity)
            }

            Image(uiImage: preview.fullFrameImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .frame(width: imageSize.width, height: imageSize.height)
        }
        .frame(width: imageSize.width, height: imageSize.height)
    }
}

enum SubjectLiftPreviewSizing {
    nonisolated static func imageSize(image: CGSize, viewport: CGSize, showsOriginal: Bool) -> CGSize {
        guard image.width > 0, image.height > 0, viewport.width > 0, viewport.height > 0 else { return .zero }
        let inset: CGFloat = showsOriginal ? 0 : 24
        let width = max(0, viewport.width - inset * 2)
        let height = max(0, viewport.height - inset * 2)
        let horizontalScale = width / image.width
        let verticalScale = height / image.height
        let scale = showsOriginal ? max(horizontalScale, verticalScale) : min(horizontalScale, verticalScale)
        return CGSize(width: image.width * scale, height: image.height * scale)
    }
}
