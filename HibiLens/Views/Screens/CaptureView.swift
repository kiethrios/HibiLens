//
//  CaptureView.swift
//  HibiLens
//
//  Created by kiethrios on 2026/4/10.
//

import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let theme = AppTheme()
    @StateObject private var camera = CameraService()
    private let subjectLiftProcessor = SubjectLiftProcessor()
    private let imageLabelClassifier: LocalImageLabelClassifier = SharedImageLabelClassifier.capture
    private let cardImageAssetGenerator = CardImageAssetGenerator()

    private let vocabularyLookup: JapaneseVocabularyLookup = BundledJapaneseVocabularyLookup.bundledOrEmpty()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var captureDraftCandidates: CaptureDraftCandidateSet?
    @State private var subjectLiftPreview: SubjectLiftPreview?
    @State private var subjectLiftAnimationPhase: SubjectLiftAnimationPhase = .glowOnOriginal
    @State private var subjectLiftGlowRotation = Angle.degrees(-120)
    @State private var isImportingPhoto = false
    @State private var isProcessingCapture = false
    @State private var captureErrorMessage: String?
    @State private var captureWorkflowTask: Task<Void, Never>?
    @State private var imageLabelClassificationTask: Task<Void, Never>?
    @State private var captureWorkflowID: UUID?
    @State private var normalizedVisibleCameraRect: CGRect?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(session: camera.session, normalizedVisibleRect: $normalizedVisibleCameraRect)
                    .ignoresSafeArea()

                previewOverlay

                if subjectLiftPreview == nil {
                    focusSquare(size: focusSquareSize(in: geometry))
                        .position(
                            x: geometry.size.width / 2,
                            y: focusSquareCenterY(in: geometry)
                        )
                }

                closeButtonOverlay(in: geometry)

                if let subjectLiftPreview {
                    subjectLiftPreviewOverlay(subjectLiftPreview, in: geometry)
                } else {
                    footer(in: geometry)
                }

                cameraStateOverlay
            }
            .background(theme.cameraPreviewBase)
            .ignoresSafeArea()
        }
        .task {
            camera.prepare()
            await prewarmImageLabelClassifier()
        }
        .onDisappear {
            stopCaptureWorkflow()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            startPhotoImport(for: newItem)
        }
        .sheet(item: $captureDraftCandidates, onDismiss: clearSubjectLiftPreviewAfterSheetDismissal) { candidates in
            CaptureMetadataEntrySheet(
                drafts: candidates.drafts,
                onCancel: { captureDraftCandidates = nil },
                onSave: { selectedDraft in
                    saveCard(from: selectedDraft)
                }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var previewOverlay: some View {
        Rectangle()
            .fill(theme.cameraPreviewScrim)
        .ignoresSafeArea()
    }

    private func focusSquare(size: CGFloat) -> some View {
        ZStack {
            cornerBracket(.topLeading)
            cornerBracket(.topTrailing)
            cornerBracket(.bottomLeading)
            cornerBracket(.bottomTrailing)

            Circle()
                .fill(theme.cameraGuidanceAccent)
                .frame(width: 4, height: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: -22)
        }
        .frame(width: size, height: size)
    }

    private func cornerBracket(_ alignment: Alignment) -> some View {
        CornerBracketShape(alignment: alignment)
            .stroke(theme.cameraGuidanceStroke, style: StrokeStyle(lineWidth: 1.2, lineCap: .square))
            .frame(width: 24, height: 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private func footer(in geometry: GeometryProxy) -> some View {
        let cameraControlForeground = theme.cameraControlForeground

        return VStack {
            Spacer(minLength: 0)

            VStack(spacing: 12) {
                if !camera.availableZoomPresets.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(camera.availableZoomPresets) { preset in
                            let isSelected = camera.selectedZoomPresetID == preset.id

                            Button {
                                camera.selectZoomPreset(preset.id)
                            } label: {
                                Text(preset.label)
                                    .font(AppTypography.labelSmall)
                                    .foregroundStyle(
                                        isSelected ? theme.cameraPreviewBase : cameraControlForeground
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(
                                        isSelected
                                            ? cameraControlForeground
                                            : theme.cameraPreviewBase.opacity(0.82),
                                        in: Circle()
                                    )
                            }
                            .disabled(isCaptureControlBusy || camera.state != .running)
                            .buttonStyle(.plain)
                            .accessibilityLabel(preset.label)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                            .animation(.easeOut(duration: 0.18), value: isSelected)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                ZStack {
                    HStack {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(AppTypography.headlineMedium)
                                .foregroundStyle(cameraControlForeground)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(isCaptureControlBusy)
                        .buttonStyle(.plain)
                        .appCircularGlassControl(fill: theme.cameraControlSurface)
                        .frame(width: 90, height: 90, alignment: .leading)
                        .padding(.leading, 43)

                        Spacer()
                    }

                    Button(action: capturePhoto) {
                        shutterButton
                    }
                    .disabled(isCaptureControlBusy)
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppL10n.Capture.capturePhoto)
                }
                .frame(maxWidth: 448)
            }
            .padding(.bottom, max(39, geometry.safeAreaInsets.bottom + 5))
        }
    }

    private func closeButtonOverlay(in geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                BackGlassButton(action: { dismiss() })

                Spacer()
            }
            .padding(.top, max(geometry.safeAreaInsets.top, 12))
            .padding(.leading, 43)

            Spacer()
        }
    }

    private var shutterButton: some View {
        ZStack {
            Circle()
                .fill(theme.cameraShutterOuterSurface)
                .background(.ultraThinMaterial, in: Circle())
                .frame(width: 74, height: 74)

            Circle()
                .fill(theme.cameraShutterInnerSurface)
                .frame(width: 56, height: 56)
                .appAmbientDepth(theme: theme, depth: .elevated)

            ZStack {
                Circle()
                    .fill(theme.cameraShutterCore)
                    .frame(width: 23.75, height: 23.75)

                Circle()
                    .fill(theme.cameraControlForeground)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 90, height: 90)
        .opacity(isCaptureControlBusy ? 0.55 : 1)
    }

    private var isCaptureWorkflowBusy: Bool {
        isImportingPhoto || isProcessingCapture || subjectLiftPreview != nil
    }

    private var isCaptureControlBusy: Bool {
        isCaptureWorkflowBusy || camera.isZoomTransitioning
    }

    @ViewBuilder
    private var cameraStateOverlay: some View {
        if let captureErrorMessage {
            cameraMessage(
                title: AppL10n.Capture.captureErrorTitle,
                message: captureErrorMessage
            )
        } else {
            switch camera.state {
            case .denied:
                cameraMessage(
                    title: AppL10n.Capture.cameraAccessNeededTitle,
                    message: AppL10n.Capture.cameraAccessNeededMessage
                )
            case .unavailable:
                cameraMessage(
                    title: AppL10n.Capture.cameraUnavailableTitle,
                    message: AppL10n.Capture.cameraUnavailableMessage
                )
            case .loading, .running:
                EmptyView()
            }
        }
    }

    private func cameraMessage(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppTypography.headlineMedium.weight(.medium))
                .foregroundStyle(theme.cameraMessagePrimaryText)

            Text(message)
                .font(AppTypography.bodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.cameraMessageSecondaryText)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(theme.cameraMessageSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 32)
    }

    private func focusSquareSize(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.height < 600 ? 156 : 258
    }

    private func focusSquareCenterY(in geometry: GeometryProxy) -> CGFloat {
        let size = focusSquareSize(in: geometry)
        let halfSize = size / 2
        let bottomPadding = max(39, geometry.safeAreaInsets.bottom + 5)
        let zoomRowHeight: CGFloat = camera.availableZoomPresets.isEmpty ? 0 : 44 + 12
        let footerHeight = 90 + bottomPadding + zoomRowHeight
        let footerTop = geometry.size.height - footerHeight
        let preferred = geometry.size.height * 0.48
        let minY = geometry.safeAreaInsets.top + halfSize
        let maxY = footerTop - 12 - halfSize
        return min(max(preferred, minY), maxY)
    }

    private func capturePhoto() {
        switch CaptureButtonAction.resolve(
            cameraState: camera.state,
            isBusy: isCaptureControlBusy,
            hasLiftPreview: subjectLiftPreview != nil
        ) {
        case .capture:
            break
        case .showMessage(let message):
            captureErrorMessage = message
            return
        case .ignore:
            return
        }

        let visibleRectAtShutter = normalizedVisibleCameraRect
        let workflowID = beginCaptureWorkflow()
        captureWorkflowTask = Task { @MainActor in
            captureErrorMessage = nil
            isProcessingCapture = true
            defer {
                if isCurrentWorkflow(workflowID) {
                    isProcessingCapture = false
                    finishCaptureWorkflow(workflowID)
                }
            }

            do {
                let capturedPhoto = try await camera.capturePhoto(normalizedVisibleRect: visibleRectAtShutter)
                try Task.checkCancellation()
                try await presentSubjectLiftPreview(
                    for: capturedPhoto.image,
                    cardRotationAngle: capturedPhoto.cardRotationAngle
                )
            } catch is CancellationError {
                captureErrorMessage = nil
            } catch let error as SubjectLiftProcessingError {
                captureErrorMessage = error.errorDescription
            } catch {
                captureErrorMessage = AppL10n.Capture.photoCaptureFailed
            }
        }
    }

    private func startPhotoImport(for item: PhotosPickerItem) {
        let workflowID = beginCaptureWorkflow()
        captureWorkflowTask = Task { @MainActor in
            await loadSelectedPhoto(item, workflowID: workflowID)
            finishCaptureWorkflow(workflowID)
        }
    }

    private func stopCaptureWorkflow() {
        normalizedVisibleCameraRect = nil
        captureWorkflowTask?.cancel()
        captureWorkflowTask = nil
        imageLabelClassificationTask?.cancel()
        imageLabelClassificationTask = nil
        captureDraftCandidates = nil
        captureWorkflowID = nil
        camera.stop()
        subjectLiftPreview = nil
        isImportingPhoto = false
        isProcessingCapture = false
    }

    private func beginCaptureWorkflow() -> UUID {
        captureWorkflowTask?.cancel()
        imageLabelClassificationTask?.cancel()
        imageLabelClassificationTask = nil
        captureDraftCandidates = nil
        let workflowID = UUID()
        captureWorkflowID = workflowID
        return workflowID
    }

    private func finishCaptureWorkflow(_ workflowID: UUID) {
        guard isCurrentWorkflow(workflowID) else { return }
        captureWorkflowTask = nil
        captureWorkflowID = nil
    }

    private func isCurrentWorkflow(_ workflowID: UUID) -> Bool {
        captureWorkflowID == workflowID
    }

    private func prewarmImageLabelClassifier() async {
        do {
            try await imageLabelClassifier.prewarm()
        } catch {
            print("[\(imageLabelClassifier.displayName)] prewarm=(error) \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem, workflowID: UUID) async {
        isImportingPhoto = true
        captureErrorMessage = nil
        defer {
            if isCurrentWorkflow(workflowID) {
                isImportingPhoto = false
                selectedPhotoItem = nil
            }
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw CaptureImportError.missingImageData
            }
            try Task.checkCancellation()

            guard let previewImage = UIImage(data: data) else {
                throw CaptureImportError.invalidImage
            }

            isProcessingCapture = true
            defer {
                if isCurrentWorkflow(workflowID) {
                    isProcessingCapture = false
                }
            }

            try await presentSubjectLiftPreview(for: previewImage)
        } catch is CancellationError {
            captureErrorMessage = nil
        } catch let error as SubjectLiftProcessingError {
            captureErrorMessage = error.errorDescription
        } catch {
            captureErrorMessage = AppL10n.Capture.selectedPhotoLoadFailed
        }
    }

    @MainActor
    private func presentSubjectLiftPreview(for image: UIImage, cardRotationAngle: CGFloat? = nil) async throws {
        let preview = try await subjectLiftProcessor.process(image, cardRotationAngle: cardRotationAngle)
        try Task.checkCancellation()
        subjectLiftPreview = preview
        await runSubjectLiftAnimation(for: preview)
    }

    @MainActor
    private func runSubjectLiftAnimation(for preview: SubjectLiftPreview) async {
        subjectLiftAnimationPhase = .glowOnOriginal
        subjectLiftGlowRotation = .degrees(-120)

        withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
            subjectLiftAnimationPhase = .glowOnOriginal
        }
        withAnimation(.linear(duration: 0.7)) {
            subjectLiftGlowRotation = .degrees(240)
        }

        do {
            try await Task.sleep(for: .milliseconds(720))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            subjectLiftAnimationPhase = .backgroundFade
        }

        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            subjectLiftAnimationPhase = .settled
        }

        guard subjectLiftAnimationPhase.completionAction == .openNewCard else { return }

        do {
            try await Task.sleep(for: .milliseconds(180))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }
        advanceToNewCard(with: preview)
    }

    @MainActor
    private func advanceToNewCard(with preview: SubjectLiftPreview) {
        guard subjectLiftPreview != nil else { return }
        imageLabelClassificationTask?.cancel()
        imageLabelClassificationTask = Task {
            do {
                let scores = try await imageLabelClassifier.classify(
                    image: preview.liftedObjectRecognitionImage,
                    topK: LocalImageLabelLogMessage.maximumLabelCount
                )
                guard !Task.isCancelled else { return }
                print(LocalImageLabelLogMessage.make(
                    backendName: imageLabelClassifier.displayName,
                    scores: scores
                ))
                presentDraftCandidates(for: preview, labels: scores.map(\.label))
            } catch is CancellationError {
                return
            } catch {
                print("[\(imageLabelClassifier.displayName)] labels=(error) \(error.localizedDescription)")
                presentDraftCandidates(for: preview, labels: ["object"])
            }
        }
    }

    @MainActor
    private func presentDraftCandidates(for preview: SubjectLiftPreview, labels: [String]) {
        guard subjectLiftPreview != nil else { return }
        let candidateLabels = labels.isEmpty ? ["object"] : labels
        let vocabularyCandidates = vocabularyLookup.lookup(
            labels: candidateLabels,
            limit: LocalImageLabelLogMessage.maximumLabelCount
        )
        let drafts = CaptureDraftCandidateBuilder.makeDrafts(
            candidates: vocabularyCandidates,
            fallbackLabels: candidateLabels,
            imageData: preview.cardImageData,
            previewImage: preview.cardPreviewImage
        )
        captureDraftCandidates = CaptureDraftCandidateSet(drafts: drafts)
    }

    @MainActor
    private func clearSubjectLiftPreviewAfterSheetDismissal() {
        subjectLiftPreview = nil
    }

    @ViewBuilder
    private func subjectLiftPreviewOverlay(_ preview: SubjectLiftPreview, in geometry: GeometryProxy) -> some View {
        SubjectLiftPreviewCanvas(
            preview: preview,
            phase: subjectLiftAnimationPhase,
            orbitRotation: subjectLiftGlowRotation
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .transition(.opacity)
    }

    @MainActor
    private func saveCard(from draft: CaptureDraft) {
        captureErrorMessage = nil
        var imageAssets: CardImageAssets?

        do {
            imageAssets = try CapturePerformanceLog.measure("card_media.assets.generate") {
                try cardImageAssetGenerator.makeAssets(
                    originalData: draft.imageData,
                    previewImage: draft.previewImage
                )
            }
            guard let imageAssets else { throw CaptureImportError.missingImageData }
            let card = VocabularyCard(
                capturedAt: .now,
                imageLocalPath: imageAssets.fullImagePath,
                thumbnailImageLocalPath: imageAssets.thumbnailImagePath,
                imageAspectRatio: imageAssets.aspectRatio,
                japaneseText: draft.metadata.japaneseText,
                kanaText: draft.metadata.optionalTrimmedValue(for: \.kanaText),
                kanjiText: draft.metadata.optionalTrimmedValue(for: \.kanjiText),
                romajiText: draft.metadata.optionalTrimmedValue(for: \.romajiText),
                translationEnglish: draft.metadata.translationEnglish,
                translationChinese: draft.metadata.translationChinese
            )
            let progress = StudyProgress(cardID: card.id)
            card.studyProgress = progress

            modelContext.insert(card)
            try modelContext.save()
            captureDraftCandidates = nil
            dismiss()
        } catch {
            if let imageAssets {
                try? LocalImageStorage.shared.removeImage(at: imageAssets.fullImagePath)
                try? LocalImageStorage.shared.removeImage(at: imageAssets.thumbnailImagePath)
            }
            captureErrorMessage = AppL10n.Capture.saveFailed
        }
    }
}

private enum CaptureImportError: Error {
    case missingImageData
    case invalidImage
}

#Preview {
    NavigationStack {
        CaptureView()
    }
    .modelContainer(PreviewModelContainer.shared)
}
