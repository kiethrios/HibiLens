//
//  AppL10n.swift
//  JapCapture
//

import Foundation

enum AppL10n {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }

    enum Common {
        static var cancel: String { AppL10n.string("common.cancel") }
        static var done: String { AppL10n.string("common.done") }
        static var save: String { AppL10n.string("common.save") }
    }

    enum Nav {
        static var home: String { AppL10n.string("nav.home") }
        static var capture: String { AppL10n.string("nav.capture") }
        static var review: String { AppL10n.string("nav.review") }
        static var personal: String { AppL10n.string("nav.personal") }
    }

    enum Home {
        static var todaysDiscovery: String { AppL10n.string("home.discovery.title") }
        static var discoverySubtitle: String { AppL10n.string("home.discovery.subtitle") }
        static var captureNow: String { AppL10n.string("home.captureNow") }
        static var keepsakes: String { AppL10n.string("home.keepsakes.title") }
        static var seeAll: String { AppL10n.string("home.seeAll") }
        static var progress: String { AppL10n.string("home.progress.title") }
        static var emptyKeepsake: String { AppL10n.string("home.emptyKeepsake") }
        static var today: String { AppL10n.string("home.stat.today") }
        static var thisMonth: String { AppL10n.string("home.stat.thisMonth") }
        static var wordsCaptured: String { AppL10n.string("home.stat.wordsCaptured") }
        static var newKeepsake: String { AppL10n.string("home.newKeepsake") }
    }

    enum Review {
        static var learning: String { AppL10n.string("review.learning") }
        static var mastered: String { AppL10n.string("review.mastered") }
        static var learningEmptyTitle: String { AppL10n.string("review.learning.empty.title") }
        static var learningEmptyMessage: String { AppL10n.string("review.learning.empty.message") }
        static var masteredEmptyTitle: String { AppL10n.string("review.mastered.empty.title") }
        static var masteredEmptyMessage: String { AppL10n.string("review.mastered.empty.message") }
        static var deleteAlertTitle: String { AppL10n.string("review.delete.alert.title") }
        static var deleteConfirmTitle: String { AppL10n.string("review.delete.confirm") }
        static func deleteCardAccessibilityLabel(_ term: String) -> String {
            String(format: AppL10n.string("review.delete.accessibility.label"), term)
        }
    }

    enum Personal {
        static var appearance: String { AppL10n.string("personal.appearance") }
        static var appearanceSystem: String { AppL10n.string("personal.appearance.system") }
        static var appearanceDay: String { AppL10n.string("personal.appearance.day") }
        static var appearanceDark: String { AppL10n.string("personal.appearance.dark") }
        static var galleryTitle: String { AppL10n.string("personal.gallery.title") }
        static var discoveries: String { AppL10n.string("personal.discoveries") }
        static var wordsCaptured: String { AppL10n.string("personal.wordsCaptured") }
        static var thisMonth: String { AppL10n.string("personal.thisMonth") }
        static var mastered: String { AppL10n.string("personal.mastered") }
        static var information: String { AppL10n.string("personal.information") }
        static var support: String { AppL10n.string("personal.support") }
        static var privacyPolicy: String { AppL10n.string("personal.privacyPolicy") }
        static var terms: String { AppL10n.string("personal.terms") }
        static var sourcesAndLicenses: String { AppL10n.string("personal.sourcesAndLicenses") }
        static var sourcesAndLicensesBody: String { AppL10n.string("personal.sourcesAndLicenses.body") }
        static var edrdgLicense: String { AppL10n.string("personal.sourcesAndLicenses.edrdgLicense") }
        static var jmdictProject: String { AppL10n.string("personal.sourcesAndLicenses.jmdictProject") }
        static var ccBySa: String { AppL10n.string("personal.sourcesAndLicenses.ccBySa") }
        static var siglipModel: String { AppL10n.string("personal.sourcesAndLicenses.siglipModel") }
        static var siglipProject: String { AppL10n.string("personal.sourcesAndLicenses.siglipProject") }
        static var apacheLicense: String { AppL10n.string("personal.sourcesAndLicenses.apacheLicense") }
    }

    enum Capture {
        static var capturePhoto: String { AppL10n.string("capture.photo.accessibility") }
        static var captureErrorTitle: String { AppL10n.string("capture.error.title") }
        static var cameraAccessNeededTitle: String { AppL10n.string("capture.cameraAccess.title") }
        static var cameraAccessNeededMessage: String { AppL10n.string("capture.cameraAccess.message") }
        static var cameraUnavailableTitle: String { AppL10n.string("capture.cameraUnavailable.title") }
        static var cameraUnavailableMessage: String { AppL10n.string("capture.cameraUnavailable.message") }
        static var photoCaptureFailed: String { AppL10n.string("capture.photo.failed") }
        static var selectedPhotoLoadFailed: String { AppL10n.string("capture.photoImport.failed") }
        static var saveFailed: String { AppL10n.string("capture.save.failed") }
        static var cameraStarting: String { AppL10n.string("capture.camera.starting") }
        static var cannotCaptureNow: String { AppL10n.string("capture.camera.cannotCaptureNow") }
        static var newCard: String { AppL10n.string("capture.newCard") }
    }

    enum SubjectLift {
        static var invalidImage: String { AppL10n.string("subjectLift.invalidImage") }
        static var noSubjectDetected: String { AppL10n.string("subjectLift.noSubjectDetected") }
        static var cutoutCreationFailed: String { AppL10n.string("subjectLift.cutoutCreationFailed") }
        static var imageEncodingFailed: String { AppL10n.string("subjectLift.imageEncodingFailed") }
    }

    enum Subscription {
        static var free: String { AppL10n.string("subscription.product.free") }
        static var proMonthly: String { AppL10n.string("subscription.product.proMonthly") }
        static var proQuarterly: String { AppL10n.string("subscription.product.proQuarterly") }
        static var proYearly: String { AppL10n.string("subscription.product.proYearly") }
    }

    enum Accessibility {
        static var back: String { AppL10n.string("accessibility.back") }
        static var playPronunciation: String { AppL10n.string("accessibility.playPronunciation") }
    }

    enum Placeholder {
        static var screenInProgress: String { AppL10n.string("placeholder.screenInProgress") }
    }
}
