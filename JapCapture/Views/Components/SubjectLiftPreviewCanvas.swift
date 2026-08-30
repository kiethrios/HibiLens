//
//  SubjectLiftPreviewCanvas.swift
//  JapCapture
//
//  Created by Codex on 2026/4/25.
//

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
                    .scaleEffect(phase.subjectScale)
                    .offset(y: phase.subjectYOffset)
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
        ZStack {
            Image(uiImage: preview.fullFrameImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
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
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
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
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
}
