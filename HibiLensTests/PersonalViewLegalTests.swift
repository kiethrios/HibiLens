import XCTest
@testable import HibiLens

final class PersonalViewLegalTests: XCTestCase {
    func testExternalSupportLinksResolveByInterfaceLanguage() {
        XCTAssertEqual(
            PersonalExternalSupportLinks.supportURL(for: Locale(identifier: "en_US"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensSupport_en.html"
        )
        XCTAssertEqual(
            PersonalExternalSupportLinks.privacyPolicyURL(for: Locale(identifier: "en_US"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensPrivacyPolicy_en.html"
        )
        XCTAssertEqual(
            PersonalExternalSupportLinks.termsURL(for: Locale(identifier: "en_US"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensTerms_en.html"
        )
        XCTAssertEqual(
            PersonalExternalSupportLinks.supportURL(for: Locale(identifier: "zh_Hans_CN"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensSupport_zh-Hans.html"
        )
        XCTAssertEqual(
            PersonalExternalSupportLinks.privacyPolicyURL(for: Locale(identifier: "zh_Hans_CN"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensPrivacyPolicy_zh-Hans.html"
        )
        XCTAssertEqual(
            PersonalExternalSupportLinks.termsURL(for: Locale(identifier: "zh_Hans_CN"))?.absoluteString,
            "https://kiethrios.github.io/PrivacyPolicy/HibiLensTerms_zh-Hans.html"
        )
    }

    func testSourcesLicensesNoticeIncludesJMDictAttributionAndRequiredLinks() throws {
        let notice = PersonalLicenseNotice.sourcesAndLicenses

        XCTAssertEqual(notice.title, "Sources & Licenses")
        XCTAssertTrue(notice.body.contains("JMdict dictionary data"))
        XCTAssertTrue(notice.body.contains("Electronic Dictionary Research and Development Group"))
        XCTAssertTrue(notice.body.contains("Creative Commons Attribution-ShareAlike 4.0 International"))
        XCTAssertTrue(notice.body.contains("James William Breen"))
        XCTAssertTrue(notice.body.contains("google/siglip-base-patch16-224 SigLIP model"))
        XCTAssertTrue(notice.body.contains("Apache License 2.0"))

        XCTAssertEqual(
            notice.links.map(\.title),
            [
                "EDRDG License",
                "JMdict/EDICT Project",
                "CC BY-SA 4.0",
                "SigLIP Model",
                "SigLIP Project",
                "Apache License 2.0"
            ]
        )
        XCTAssertEqual(notice.links[0].url.absoluteString, "https://www.edrdg.org/edrdg/licence.html")
        XCTAssertEqual(
            notice.links[1].url.absoluteString,
            "https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project"
        )
        XCTAssertEqual(notice.links[2].url.absoluteString, "https://creativecommons.org/licenses/by-sa/4.0/")
        XCTAssertEqual(notice.links[3].url.absoluteString, "https://huggingface.co/google/siglip-base-patch16-224")
        XCTAssertEqual(notice.links[4].url.absoluteString, "https://github.com/google-research/big_vision")
        XCTAssertEqual(notice.links[5].url.absoluteString, "https://www.apache.org/licenses/LICENSE-2.0")
    }

    func testPersonalVisualRefillUsesApprovedGalleryCopy() {
        XCTAssertEqual(PersonalAppearanceSpec.title, "Appearance")
        XCTAssertEqual(PersonalVisualRefillSpec.title, "Your Gallery")
        XCTAssertEqual(PersonalVisualRefillSpec.discoveriesLabel, "Discoveries")
        XCTAssertEqual(PersonalVisualRefillSpec.discoveryUnitLabel, "Words Captured")
        XCTAssertEqual(PersonalVisualRefillSpec.thisMonthLabel, "This Month")
        XCTAssertEqual(PersonalVisualRefillSpec.masteredLabel, "Mastered")
        XCTAssertEqual(PersonalVisualRefillSpec.informationLabel, "Information")
        XCTAssertEqual(PersonalVisualRefillSpec.supportLabel, "Support")
        XCTAssertEqual(PersonalVisualRefillSpec.privacyPolicyLabel, "Privacy Policy")
        XCTAssertEqual(PersonalVisualRefillSpec.termsLabel, "Terms")
        XCTAssertEqual(PersonalVisualRefillSpec.sourcesAndLicensesLabel, "Sources & Licenses")
    }

    @MainActor
    func testPersonalAppearanceSpecUsesApprovedLocalizedCopy() {
        XCTAssertEqual(PersonalAppearanceSpec.title, "Appearance")
        XCTAssertEqual(PersonalAppearanceSpec.title(for: .system), "Follow System")
        XCTAssertEqual(PersonalAppearanceSpec.title(for: .day), "Day")
        XCTAssertEqual(PersonalAppearanceSpec.title(for: .dark), "Dark")
    }

    @MainActor
    func testPersonalAppearanceSpecSupportsEveryPreference() {
        XCTAssertEqual(
            AppAppearancePreference.allCases.map(PersonalAppearanceSpec.title(for:)),
            ["Follow System", "Day", "Dark"]
        )
    }

    func testPersonalVisualRefillRejectsPreviousDiscoveryCopy() {
        XCTAssertNotEqual(PersonalVisualRefillSpec.discoveryUnitLabel, "words captured")

        let approvedCopy = [
            PersonalVisualRefillSpec.title,
            PersonalVisualRefillSpec.discoveriesLabel,
            PersonalVisualRefillSpec.discoveryUnitLabel,
            PersonalVisualRefillSpec.thisMonthLabel,
            PersonalVisualRefillSpec.masteredLabel,
            PersonalVisualRefillSpec.informationLabel,
            PersonalVisualRefillSpec.supportLabel,
            PersonalVisualRefillSpec.privacyPolicyLabel,
            PersonalVisualRefillSpec.termsLabel,
            PersonalVisualRefillSpec.sourcesAndLicensesLabel
        ]

        XCTAssertFalse(approvedCopy.contains("Your Japanese collection is taking shape."))
    }

    func testPersonalVisualRefillRemovesDashboardCopy() {
        let removedCopy = [
            "Monthly Accomplishment",
            "WORDS CAPTURED THIS MONTH",
            "Total",
            "Information & Support",
            "Terms and Conditions"
        ]

        XCTAssertFalse(removedCopy.contains(PersonalVisualRefillSpec.title))
        XCTAssertFalse(removedCopy.contains(PersonalVisualRefillSpec.discoveriesLabel))
        XCTAssertFalse(removedCopy.contains(PersonalVisualRefillSpec.informationLabel))
        XCTAssertFalse(removedCopy.contains(PersonalVisualRefillSpec.termsLabel))
    }

    func testPersonalGalleryMetricsCountTotalMonthAndMasteredCards() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 15
        ).date!
        let thisMonth = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 3
        ).date!
        let previousMonth = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 28
        ).date!

        let learnedCard = VocabularyCard(
            capturedAt: thisMonth,
            imageLocalPath: "processed-images/phone.png",
            japaneseText: "携帯電話",
            translationEnglish: "Mobile phone",
            translationChinese: "手机"
        )
        let masteredThisMonth = VocabularyCard(
            capturedAt: thisMonth,
            imageLocalPath: "processed-images/book.png",
            japaneseText: "本",
            translationEnglish: "Book",
            translationChinese: "书"
        )
        let masteredPreviousMonth = VocabularyCard(
            capturedAt: previousMonth,
            imageLocalPath: "processed-images/cup.png",
            japaneseText: "カップ",
            translationEnglish: "Cup",
            translationChinese: "杯子"
        )

        let firstProgress = StudyProgress(cardID: masteredThisMonth.id)
        firstProgress.markMastered(at: thisMonth)
        masteredThisMonth.studyProgress = firstProgress

        let secondProgress = StudyProgress(cardID: masteredPreviousMonth.id)
        secondProgress.markMastered(at: previousMonth)
        masteredPreviousMonth.studyProgress = secondProgress

        let metrics = PersonalGalleryMetrics.from(
            cards: [learnedCard, masteredThisMonth, masteredPreviousMonth],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(metrics.totalDiscoveries, 3)
        XCTAssertEqual(metrics.thisMonth, 2)
        XCTAssertEqual(metrics.mastered, 2)
    }
}
