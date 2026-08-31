import AVFoundation
import SwiftData
import UIKit
import XCTest
@testable import HibiLens

final class HibiLensDataModelTests: XCTestCase {
    func testNavDestinationKeepsStableIDsSeparateFromLocalizedTitles() {
        XCTAssertEqual(NavDestination.allCases, [.home, .capture, .review, .personal])
        XCTAssertEqual(NavDestination.allCases.map(\.id), ["home", "capture", "review", "personal"])
        XCTAssertEqual(NavDestination.allCases.map(\.title), ["Home", "Capture", "Review", "Personal"])
        XCTAssertEqual(NavDestination.allCases.map(\.symbol), ["house", "camera", "menucard", "person"])
    }

    func testPersistentStoreDirectoryCreatesApplicationSupportDirectory() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HibiLensTests-\(UUID().uuidString)", isDirectory: true)
        let applicationSupportURL = rootURL.appendingPathComponent("Application Support", isDirectory: true)

        try AppStorageBootstrap.ensureApplicationSupportDirectoryExists(at: applicationSupportURL)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: applicationSupportURL.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testStoredImageMemoryCacheStoresImageByRelativePath() {
        let cache = StoredImageMemoryCache()
        let image = makeImage(size: CGSize(width: 12, height: 8), color: .systemBlue)

        cache.store(image, for: "processed-thumbnails/card.png")

        XCTAssertTrue(cache.image(for: "processed-thumbnails/card.png") === image)
        XCTAssertNil(cache.image(for: "processed-thumbnails/other-card.png"))
    }

    func testStoredImageLoaderReadsCachedThumbnailSynchronously() {
        let cache = StoredImageMemoryCache()
        let image = makeImage(size: CGSize(width: 12, height: 8), color: .systemGreen)

        cache.store(image, for: "processed-thumbnails/card.png")

        XCTAssertTrue(
            StoredImageLoader.cachedImage(
                at: "processed-thumbnails/card.png",
                in: cache
            ) === image
        )
    }

    func testVocabularyDetailImagePathsUseThumbnailPreviewBeforeFullImage() {
        let item = CaptureItem(
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/card.png",
            thumbnailImagePath: "processed-thumbnails/card.png",
            imageAspectRatio: 1
        )

        let imagePaths = VocabularyDetailImagePaths(item: item)

        XCTAssertEqual(imagePaths.previewPath, "processed-thumbnails/card.png")
        XCTAssertEqual(imagePaths.fullPath, "processed-images/card.png")
    }

    func testCaptureCardDisplayContentPrefersStoredReadingRomajiAndTranslation() {
        let item = CaptureItem(
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png",
            romaji: "Neko",
            kana: "ねこ",
            translation: "Cat"
        )

        let displayContent = CaptureCardDisplayContent.from(item)

        XCTAssertEqual(displayContent.japanese, "猫")
        XCTAssertEqual(displayContent.reading, "ねこ")
        XCTAssertEqual(displayContent.romaji, "Neko")
        XCTAssertEqual(displayContent.translation, "Cat")
    }

    func testCaptureCardDisplayContentRepeatsKanaOnlyWordToPreserveRhythm() {
        let item = CaptureItem(
            japanese: "コンビニ",
            english: "CONVENIENCE STORE",
            localImagePath: "processed-images/konbini.png",
            romaji: "Konbini",
            kana: nil,
            translation: "Convenience store"
        )

        let displayContent = CaptureCardDisplayContent.from(item)

        XCTAssertEqual(displayContent.japanese, "コンビニ")
        XCTAssertEqual(displayContent.reading, "コンビニ")
        XCTAssertEqual(displayContent.romaji, "Konbini")
        XCTAssertEqual(displayContent.translation, "Convenience store")
    }

    func testPronunciationTextPrefersProvidedText() {
        let item = CaptureItem(
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png",
            romaji: "Neko",
            kana: "ねこ",
            translation: "Cat"
        )

        XCTAssertEqual(
            PronunciationText.source(
                preferred: item.kana,
                fallback: item.japanese
            ),
            "ねこ"
        )
    }

    func testPronunciationTextFallsBackToFallbackText() {
        let item = CaptureItem(
            japanese: "コンビニ",
            english: "CONVENIENCE STORE",
            localImagePath: "processed-images/konbini.png",
            romaji: "Konbini",
            kana: nil,
            translation: "Convenience store"
        )

        XCTAssertEqual(
            PronunciationText.source(
                preferred: item.kana,
                fallback: item.japanese
            ),
            "コンビニ"
        )
    }

    func testPronunciationAudioSessionPolicyUsesPlaybackCategoryForSilentSwitchPlayback() {
        XCTAssertEqual(PronunciationAudioSessionPolicy.category, .playback)
        XCTAssertEqual(PronunciationAudioSessionPolicy.mode, .spokenAudio)
    }

    func testStoredImageViewDefaultsToFitModeForCompleteSubjectDisplay() {
        XCTAssertEqual(StoredImageContentMode.default, .fit)
    }

    func testReviewCardImageStageIntegratesWithCardSurfaceInLightMode() {
        XCTAssertEqual(AppTheme().reviewCardImageStage, .integratedWithCardSurface)
    }

    func testExpandedObjectDetailLayoutMakesCardFullScreen() {
        let layout = ExpandedObjectDetailLayout(containerSize: CGSize(width: 390, height: 844))

        XCTAssertEqual(layout.cardFrame, CGRect(x: 0, y: 0, width: 390, height: 844))
        XCTAssertLessThan(layout.imageFrame.maxY, layout.textTopY)
        XCTAssertTrue(layout.cardFrame.contains(layout.imageFrame))
        XCTAssertTrue(layout.cardFrame.contains(CGPoint(x: layout.cardFrame.midX, y: layout.textTopY)))
    }

    func testExpandedObjectDetailStyleKeepsCardSurfaceButNotImageStageBackground() {
        XCTAssertTrue(ExpandedObjectDetailStyle.usesCardSurface)
        XCTAssertTrue(ExpandedObjectDetailStyle.usesClearImageStage)
    }

    func testExpandedObjectDetailNavigationUsesSystemZoomAndBackGesture() {
        XCTAssertFalse(ExpandedObjectDetailNavigation.usesSystemZoomTransition)
        XCTAssertFalse(ExpandedObjectDetailNavigation.usesSystemBackGesture)
        XCTAssertTrue(ExpandedObjectDetailNavigation.usesManualFrameOverlayTransition)
        XCTAssertTrue(ExpandedObjectDetailNavigation.usesHeroImageTransitionLayer)
        XCTAssertFalse(ExpandedObjectDetailNavigation.scalesLiveDetailViewDuringTransition)
        XCTAssertTrue(ExpandedObjectDetailNavigation.usesOverlayBackButton)
        XCTAssertTrue(ExpandedObjectDetailNavigation.usesPagedCardSwipe)
    }

    func testVocabularyDetailTransitionFrameExpandsFromSourceFrameToFullScreen() {
        let sourceFrame = CGRect(x: 24, y: 120, width: 168, height: 220)
        let containerSize = CGSize(width: 390, height: 844)

        XCTAssertEqual(
            VocabularyDetailTransitionFrame.frame(
                sourceFrame: sourceFrame,
                containerSize: containerSize,
                isExpanded: false
            ),
            sourceFrame
        )
        XCTAssertEqual(
            VocabularyDetailTransitionFrame.frame(
                sourceFrame: sourceFrame,
                containerSize: containerSize,
                isExpanded: true
            ),
            CGRect(origin: .zero, size: containerSize)
        )
    }

    func testVocabularyDetailBackButtonSitsBelowSafeArea() {
        XCTAssertEqual(
            VocabularyDetailBackButtonPlacement.topPadding(safeAreaTop: 47),
            59
        )
        XCTAssertEqual(
            VocabularyDetailBackButtonPlacement.topPadding(safeAreaTop: 0),
            16
        )
    }

    func testVocabularyDetailTransitionDelaysFullImageUntilExpansionSettles() {
        XCTAssertFalse(
            VocabularyDetailImageLoadingPolicy.shouldLoadFullImage(
                isExpanded: false,
                hasSettled: false
            )
        )
        XCTAssertFalse(
            VocabularyDetailImageLoadingPolicy.shouldLoadFullImage(
                isExpanded: true,
                hasSettled: false
            )
        )
        XCTAssertTrue(
            VocabularyDetailImageLoadingPolicy.shouldLoadFullImage(
                isExpanded: true,
                hasSettled: true
            )
        )
    }

    func testVocabularyDetailHeroImageFrameExpandsFromSourceImageToDetailImageFrame() {
        let sourceFrame = CGRect(x: 32, y: 160, width: 144, height: 144)
        let targetFrame = CGRect(x: 40, y: 228, width: 310, height: 310)

        XCTAssertEqual(
            VocabularyDetailHeroImageTransition.frame(
                sourceFrame: sourceFrame,
                targetFrame: targetFrame,
                isExpanded: false
            ),
            sourceFrame
        )
        XCTAssertEqual(
            VocabularyDetailHeroImageTransition.frame(
                sourceFrame: sourceFrame,
                targetFrame: targetFrame,
                isExpanded: true
            ),
            targetFrame
        )
    }

    func testVocabularyDetailDismissalRevealsExpandedHeroBeforeCollapsing() {
        let item = CaptureItem(
            id: UUID(uuidString: "2D0D0F2A-CB70-4B7B-9A2F-00D6C04BB4D1")!,
            japanese: "本",
            english: "BOOK",
            localImagePath: "processed-images/book.png"
        )
        let session = VocabularyDetailSession(selected: item, in: [item])!
        var presentation = VocabularyDetailPresentation(
            session: session,
            sourceFrame: CGRect(x: 32, y: 160, width: 144, height: 144)
        )
        presentation.isExpanded = true
        presentation.hasSettled = true

        presentation.prepareForDismissalHeroReveal()

        XCTAssertTrue(presentation.isExpanded)
        XCTAssertFalse(presentation.hasSettled)

        presentation.collapseDismissalHero()

        XCTAssertFalse(presentation.isExpanded)
        XCTAssertFalse(presentation.hasSettled)
    }

    func testVocabularyDetailHeroImageUsesMeasuredTargetFrameWhenAvailable() {
        let measuredFrame = CGRect(x: 38, y: 226, width: 314, height: 314)
        let fallbackFrame = CGRect(x: 40, y: 228, width: 310, height: 310)

        XCTAssertEqual(
            VocabularyDetailHeroImageTransition.targetFrame(
                measuredFrame: measuredFrame,
                fallbackFrame: fallbackFrame
            ),
            measuredFrame
        )
        XCTAssertEqual(
            VocabularyDetailHeroImageTransition.targetFrame(
                measuredFrame: .zero,
                fallbackFrame: fallbackFrame
            ),
            fallbackFrame
        )
    }

    func testVocabularyDetailTransitionWaitsForFrameMeasurementBeforeAnimating() {
        XCTAssertGreaterThanOrEqual(
            VocabularyDetailTransitionTiming.initialMeasurementDelay,
            0.03
        )
    }

    func testVocabularyDetailTransitionUsesStableCaptureItemID() {
        let item = CaptureItem(
            id: UUID(uuidString: "5839FC2B-6071-46A8-A953-247A03D91F32")!,
            japanese: "火",
            english: "FIRE",
            localImagePath: "processed-images/fire.png"
        )

        XCTAssertEqual(VocabularyDetailTransition.sourceID(for: item), item.id)
    }

    func testVocabularyDetailSessionKeepsSourceOrderAndSelectedCard() {
        let first = CaptureItem(
            id: UUID(uuidString: "32AD5423-6C83-46EE-897D-457173D41D57")!,
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png"
        )
        let second = CaptureItem(
            id: UUID(uuidString: "32D6C264-5320-47D1-9723-4D8D8F42C596")!,
            japanese: "水",
            english: "WATER",
            localImagePath: "processed-images/water.png"
        )
        let third = CaptureItem(
            id: UUID(uuidString: "7BD271C7-FC93-4F22-A4F9-8C5076AD448C")!,
            japanese: "火",
            english: "FIRE",
            localImagePath: "processed-images/fire.png"
        )

        let session = VocabularyDetailSession(selected: second, in: [first, second, third])

        XCTAssertEqual(session?.selectedID, second.id)
        XCTAssertEqual(session?.items.map(\.id), [first.id, second.id, third.id])
    }

    func testVocabularyDetailSessionDefaultsToCaptureSourceWithMasteredAction() {
        let item = CaptureItem(
            id: UUID(uuidString: "C5C74D8C-B1E3-437D-863E-7F88B0BCA87F")!,
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png"
        )

        let session = VocabularyDetailSession(selected: item, in: [item])

        XCTAssertEqual(session?.source, .todaysCaptures)
        XCTAssertEqual(session?.source.reviewButtonTitle, "Mastered")
        XCTAssertTrue(session?.source.removesCardAfterReviewAction ?? false)
    }

    func testVocabularyDetailSessionUsesLearningActionForMasteredReviewSource() {
        let item = CaptureItem(
            id: UUID(uuidString: "26D7AD47-6A5E-4550-B119-2BD97D270BDF")!,
            japanese: "水",
            english: "WATER",
            localImagePath: "processed-images/water.png"
        )

        let session = VocabularyDetailSession(
            selected: item,
            in: [item],
            source: .masteredReview
        )

        XCTAssertEqual(session?.source.reviewButtonTitle, "Learning")
        XCTAssertTrue(session?.source.removesCardAfterReviewAction ?? false)
    }

    func testVocabularyDetailSessionFiltersPlaceholdersAndRejectsPlaceholderSelection() {
        let realCard = CaptureItem(
            id: UUID(uuidString: "63F4903B-C7D8-4606-9652-9E8F5A49B019")!,
            japanese: "犬",
            english: "DOG",
            localImagePath: "processed-images/dog.png"
        )
        let placeholder = CaptureItem(placeholder: ())

        let realSession = VocabularyDetailSession(selected: realCard, in: [placeholder, realCard])
        let placeholderSession = VocabularyDetailSession(selected: placeholder, in: [placeholder, realCard])

        XCTAssertEqual(realSession?.items, [realCard])
        XCTAssertNil(placeholderSession)
    }

    func testVocabularyDetailSessionRemovalChoosesNextCardWhenAvailable() {
        let first = CaptureItem(
            id: UUID(uuidString: "2C397A62-D222-4B32-916B-48A69B563E5B")!,
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png"
        )
        let second = CaptureItem(
            id: UUID(uuidString: "38140798-22E1-4217-A507-6332BD503CF5")!,
            japanese: "水",
            english: "WATER",
            localImagePath: "processed-images/water.png"
        )
        let third = CaptureItem(
            id: UUID(uuidString: "5E68427D-3A86-4D52-A424-7873164C9174")!,
            japanese: "火",
            english: "FIRE",
            localImagePath: "processed-images/fire.png"
        )
        let session = VocabularyDetailSession(selected: second, in: [first, second, third])!

        let result = session.removingItem(withID: second.id)

        XCTAssertEqual(result.items.map(\.id), [first.id, third.id])
        XCTAssertEqual(result.selectedID, third.id)
    }

    func testVocabularyDetailSessionRemovalChoosesPreviousCardWhenRemovingLastCard() {
        let first = CaptureItem(
            id: UUID(uuidString: "32430394-FA38-481C-AE7F-FF05FBC2354C")!,
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png"
        )
        let second = CaptureItem(
            id: UUID(uuidString: "34314308-1A6E-4C8B-93A7-163F41B1D3D5")!,
            japanese: "水",
            english: "WATER",
            localImagePath: "processed-images/water.png"
        )
        let session = VocabularyDetailSession(selected: second, in: [first, second])!

        let result = session.removingItem(withID: second.id)

        XCTAssertEqual(result.items.map(\.id), [first.id])
        XCTAssertEqual(result.selectedID, first.id)
    }

    func testVocabularyDetailSessionRemovalCanEmptySession() {
        let item = CaptureItem(
            id: UUID(uuidString: "5BD55352-0C40-4B92-A7AB-D6C8BE640329")!,
            japanese: "猫",
            english: "CAT",
            localImagePath: "processed-images/cat.png"
        )
        let session = VocabularyDetailSession(selected: item, in: [item])!

        let result = session.removingItem(withID: item.id)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertNil(result.selectedID)
    }

    func testTodaysCaptureCardTapActionOpensRealCardsAndKeepsPlaceholderCaptureShortcut() {
        let realCapture = CaptureItem(
            japanese: "火",
            english: "FIRE",
            localImagePath: "processed-images/fire.png"
        )
        let placeholderCapture = CaptureItem(placeholder: ())

        XCTAssertEqual(HomeCaptureCardTapAction.forItem(realCapture), .openCard)
        XCTAssertEqual(HomeCaptureCardTapAction.forItem(placeholderCapture), .createCapture)
    }

    func testTodaysCaptureItemsIncludesLearningCardsCapturedTodayPlusPlaceholder() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 26, hour: 12))!
        let todayEarlier = calendar.date(from: DateComponents(year: 2026, month: 4, day: 26, hour: 9))!
        let todayLater = calendar.date(from: DateComponents(year: 2026, month: 4, day: 26, hour: 11))!
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 4, day: 25, hour: 23))!
        let masteredToday = calendar.date(from: DateComponents(year: 2026, month: 4, day: 26, hour: 10))!
        let mouse = VocabularyCard(
            capturedAt: todayEarlier,
            imageLocalPath: "processed-images/mouse.png",
            japaneseText: "鼠",
            translationEnglish: "Mouse",
            translationChinese: "鼠"
        )
        let controller = VocabularyCard(
            capturedAt: todayLater,
            imageLocalPath: "processed-images/controller.png",
            japaneseText: "コントローラー",
            translationEnglish: "Controller",
            translationChinese: "控制器"
        )
        let masteredCard = VocabularyCard(
            capturedAt: masteredToday,
            imageLocalPath: "processed-images/mastered.png",
            japaneseText: "机",
            translationEnglish: "Desk",
            translationChinese: "桌子"
        )
        masteredCard.studyProgress = StudyProgress(cardID: masteredCard.id, state: .mastered)
        let olderCard = VocabularyCard(
            capturedAt: yesterday,
            imageLocalPath: "processed-images/older.png",
            japaneseText: "水",
            translationEnglish: "Water",
            translationChinese: "水"
        )

        let items = HomeCaptureItems.todaysItems(
            from: [mouse, olderCard, masteredCard, controller],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, controller.id)
        XCTAssertEqual(items[1].id, mouse.id)
        XCTAssertFalse(items.contains { $0.id == olderCard.id })
        XCTAssertFalse(items.contains { $0.id == masteredCard.id })
        XCTAssertTrue(items[2].isPlaceholder)
    }

    func testTranslationDisplayPrefersChineseForChineseLanguageCode() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "水",
            translationEnglish: "Water",
            translationChinese: "水"
        )

        XCTAssertEqual(card.translation(forLanguageCode: "zh-Hans"), "水")
        XCTAssertEqual(card.translation(forLanguageCode: "en-US"), "Water")
    }

    func testLocalImageStorageWritesAndLoadsPNGData() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LocalImageStorage(rootURL: rootURL)
        let imageData = try XCTUnwrap(makeImageData(color: .systemTeal))

        let relativePath = try storage.saveProcessedImageData(imageData)
        let loadedData = try storage.loadImageData(at: relativePath)

        XCTAssertEqual(loadedData, imageData)
        XCTAssertTrue(relativePath.hasPrefix("processed-images/"))
    }

    func testCardImageAssetGeneratorSavesFullImageThumbnailAndAspectRatio() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LocalImageStorage(rootURL: rootURL)
        let generator = CardImageAssetGenerator(
            storage: storage,
            thumbnailMaxPixelLength: 320
        )
        let image = makeImage(size: CGSize(width: 1_200, height: 600), color: .systemTeal)
        let imageData = try XCTUnwrap(image.pngData())

        let assets = try generator.makeAssets(
            originalData: imageData,
            previewImage: image
        )

        let fullImage = try storage.loadImage(at: assets.fullImagePath)
        let thumbnailImage = try storage.loadImage(at: assets.thumbnailImagePath)

        XCTAssertTrue(assets.fullImagePath.hasPrefix("processed-images/"))
        XCTAssertTrue(assets.thumbnailImagePath.hasPrefix("processed-thumbnails/"))
        XCTAssertEqual(fullImage.size.width / fullImage.size.height, 2.0, accuracy: 0.001)
        XCTAssertLessThanOrEqual(max(thumbnailImage.size.width, thumbnailImage.size.height), 320)
        XCTAssertEqual(assets.aspectRatio, 2.0, accuracy: 0.001)
    }

    func testVocabularyCardCaptureItemIncludesThumbnailAndAspectRatio() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "processed-images/card.png",
            thumbnailImageLocalPath: "processed-thumbnails/card.png",
            imageAspectRatio: 1.6,
            japaneseText: "水",
            translationEnglish: "Water",
            translationChinese: "水"
        )

        let item = card.captureItem(languageCode: "en-US")

        XCTAssertEqual(item.localImagePath, "processed-images/card.png")
        XCTAssertEqual(item.thumbnailImagePath, "processed-thumbnails/card.png")
        XCTAssertEqual(item.imageAspectRatio, 1.6)
    }

    func testVocabularyCardPersistsWithOptionalReadingFieldsUnset() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: VocabularyCard.self,
            StudyProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "本",
            translationEnglish: "Book",
            translationChinese: "书"
        )
        card.studyProgress = StudyProgress(cardID: card.id)
        context.insert(card)
        try context.save()

        let descriptor = FetchDescriptor<VocabularyCard>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertNil(fetched.first?.kanaText)
        XCTAssertNil(fetched.first?.kanjiText)
        XCTAssertNil(fetched.first?.romajiText)
        XCTAssertEqual(fetched.first?.studyProgress?.cardID, fetched.first?.id)
    }

    func testStudyProgressDefaultsToNewState() {
        let progress = StudyProgress(cardID: UUID())

        XCTAssertEqual(progress.state, .new)
        XCTAssertNil(progress.markedLearnedAt)
        XCTAssertNil(progress.markedMasteredAt)
        XCTAssertNotNil(progress.createdAt)
        XCTAssertNotNil(progress.updatedAt)
    }

    func testStudyProgressMarksLearnedAndMasteredWithTimestamps() {
        let learnedAt = Date(timeIntervalSince1970: 1_000)
        let masteredAt = Date(timeIntervalSince1970: 2_000)
        let progress = StudyProgress(cardID: UUID())

        progress.markLearned(at: learnedAt)
        progress.markMastered(at: masteredAt)

        XCTAssertEqual(progress.state, .mastered)
        XCTAssertEqual(progress.markedLearnedAt, learnedAt)
        XCTAssertEqual(progress.markedMasteredAt, masteredAt)
        XCTAssertEqual(progress.lastTouchedAt, masteredAt)
    }

    func testNewVocabularyCardStartsWithAttachedStudyProgress() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        let progress = StudyProgress(cardID: card.id)
        card.studyProgress = progress

        XCTAssertEqual(card.studyProgress?.state, .new)
        XCTAssertEqual(card.studyProgress?.cardID, card.id)
    }

    func testVocabularyCardPersistsWithStudyProgress() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: VocabularyCard.self,
            StudyProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        let progress = StudyProgress(cardID: card.id)
        card.studyProgress = progress

        context.insert(card)
        try context.save()

        let verificationContext = ModelContext(container)
        let fetchedCards = try verificationContext.fetch(FetchDescriptor<VocabularyCard>())
        XCTAssertEqual(fetchedCards.count, 1)
        XCTAssertNotNil(fetchedCards.first?.studyProgress)
        XCTAssertEqual(fetchedCards.first?.studyProgress?.state, .new)
        XCTAssertEqual(fetchedCards.first?.studyProgress?.cardID, fetchedCards.first?.id)
    }

    func testReviewCardDeletionRemovesCardAndCascadesStudyProgress() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: VocabularyCard.self,
            StudyProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        card.studyProgress = StudyProgress(cardID: card.id, state: .learned)

        context.insert(card)
        try context.save()

        ReviewCardDeletion.delete(card, in: context)
        try context.save()

        let verificationContext = ModelContext(container)
        let fetchedCards = try verificationContext.fetch(FetchDescriptor<VocabularyCard>())
        let fetchedProgress = try verificationContext.fetch(FetchDescriptor<StudyProgress>())

        XCTAssertTrue(fetchedCards.isEmpty)
        XCTAssertTrue(fetchedProgress.isEmpty)
    }

    func testReviewCardJiggleParametersVaryByStableCardID() throws {
        let firstID = try XCTUnwrap(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let secondID = try XCTUnwrap(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))

        let first = ReviewCardJiggleParameters.forCard(id: firstID)
        let repeatedFirst = ReviewCardJiggleParameters.forCard(id: firstID)
        let second = ReviewCardJiggleParameters.forCard(id: secondID)

        XCTAssertEqual(first, repeatedFirst)
        XCTAssertNotEqual(first, second)
        XCTAssertGreaterThan(first.duration, 0)
        XCTAssertGreaterThanOrEqual(first.delay, 0)
        XCTAssertGreaterThan(first.angleDegrees, 0)
    }

    func testReviewDeleteModeDismissalOnlyComesFromBackgroundOrTabSwitch() {
        XCTAssertTrue(
            ReviewDeleteModeDismissal.shouldDismiss(
                isDeleteModeActive: true,
                target: .background
            )
        )
        XCTAssertTrue(
            ReviewDeleteModeDismissal.shouldDismiss(
                isDeleteModeActive: true,
                target: .segmentedControl
            )
        )
        XCTAssertFalse(
            ReviewDeleteModeDismissal.shouldDismiss(
                isDeleteModeActive: true,
                target: .card
            )
        )
        XCTAssertFalse(
            ReviewDeleteModeDismissal.shouldDismiss(
                isDeleteModeActive: true,
                target: .deleteButton
            )
        )
        XCTAssertFalse(
            ReviewDeleteModeDismissal.shouldDismiss(
                isDeleteModeActive: false,
                target: .background
            )
        )
    }

    func testVocabularyCardMatchesReviewBucketFromStudyProgress() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "川",
            translationEnglish: "River",
            translationChinese: "河"
        )

        card.studyProgress = StudyProgress(cardID: card.id, state: .new)
        XCTAssertTrue(card.matchesReviewBucket(.learned))
        XCTAssertFalse(card.matchesReviewBucket(.mastered))

        card.studyProgress = StudyProgress(cardID: card.id, state: .mastered)

        XCTAssertFalse(card.matchesReviewBucket(.learned))
        XCTAssertTrue(card.matchesReviewBucket(.mastered))
    }

    func testVocabularyCardReviewToggleShowsMasteredActionForLearningCards() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        card.studyProgress = StudyProgress(cardID: card.id, state: .learned)

        XCTAssertEqual(card.reviewBucketToggleTitle, "Mastered")
    }

    func testVocabularyCardReviewToggleShowsLearningActionForMasteredCards() {
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        card.studyProgress = StudyProgress(cardID: card.id, state: .mastered)

        XCTAssertEqual(card.reviewBucketToggleTitle, "Learning")
    }

    func testVocabularyCardReviewToggleMovesLearningCardToMastered() {
        let date = Date(timeIntervalSince1970: 1_000)
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        card.studyProgress = StudyProgress(cardID: card.id, state: .learned)

        card.toggleReviewBucket(at: date)

        XCTAssertEqual(card.currentStudyState, .mastered)
        XCTAssertEqual(card.studyProgress?.markedMasteredAt, date)
    }

    func testVocabularyCardReviewToggleMovesMasteredCardToLearning() {
        let date = Date(timeIntervalSince1970: 2_000)
        let card = VocabularyCard(
            capturedAt: .now,
            imageLocalPath: "images/test.png",
            japaneseText: "猫",
            translationEnglish: "Cat",
            translationChinese: "猫"
        )
        card.studyProgress = StudyProgress(cardID: card.id, state: .mastered)

        card.toggleReviewBucket(at: date)

        XCTAssertEqual(card.currentStudyState, .learned)
        XCTAssertNil(card.studyProgress?.markedMasteredAt)
        XCTAssertEqual(card.studyProgress?.lastTouchedAt, date)
    }

    private func makeImageData(color: UIColor) -> Data? {
        makeImage(size: CGSize(width: 8, height: 8), color: color).pngData()
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image
    }
}
