import SwiftUI

enum AppLayout {
    static let screenHorizontalPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 16
    static let homeSectionSpacing: CGFloat = 46
    static let reviewFloatingControlTopInset: CGFloat = screenTopPadding
    static let reviewFloatingControlHorizontalInset: CGFloat = screenHorizontalPadding
    static let bottomNavBarHeight: CGFloat = 54
    static let bottomNavContentInset: CGFloat = 12
    static let editorialSectionInnerGutter: CGFloat = 8
    static let compactCardGap: CGFloat = 8
    static let compactCaptureCardWidth: CGFloat = 170
    static let compactCaptureCardHeight: CGFloat = 286
    static let compactCaptureCardImageHeight: CGFloat = compactCaptureCardWidth
    static let compactCaptureCardTextSpacing: CGFloat = 6
    static let compactCaptureCardTextPadding: CGFloat = 16
    static let editorialHeaderOffset: CGFloat = 18
    static let editorialHeaderMetricDrop: CGFloat = 8
    static let nestedCardCornerRadius: CGFloat = 12
    static let contentSpacing: CGFloat = 16
    static let cardContentPadding: CGFloat = 24
    static let listRowHeight: CGFloat = 60
    static let sectionHeaderToContentSpacing: CGFloat = 18
    static let galleryCardGap: CGFloat = 16
    static let cardImageToTextSpacing: CGFloat = 16
    static let cardWordStackSpacing: CGFloat = 6

    static let keepsakeCardCornerRadius: CGFloat = 22
    static let compactKeepsakeCardCornerRadius: CGFloat = 14
    static let imageFrameCornerRadius: CGFloat = 16
    static let subjectStageCornerRadius: CGFloat = 18
    static let sheetCornerRadius: CGFloat = 28
    static let glassControlCornerRadius: CGFloat = 22
    static let pillCornerRadius: CGFloat = 999

    static let dailyDiscoveryMinHeight: CGFloat = 180
    static let dailyDiscoveryMaxHeight: CGFloat = 240
    static let detailSubjectStageMinHeight: CGFloat = 320
    static let detailSubjectStageMaxHeight: CGFloat = 420
    static let lensCaptureButtonDiameter: CGFloat = 188
    static let compactCaptureIconDiameter: CGFloat = 52
}

private struct BottomNavContentInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = AppLayout.bottomNavContentInset
}

extension EnvironmentValues {
    var bottomNavContentInset: CGFloat {
        get { self[BottomNavContentInsetKey.self] }
        set { self[BottomNavContentInsetKey.self] = newValue }
    }
}

private struct AppScreenPaddingModifier: ViewModifier {
    @Environment(\.bottomNavContentInset) private var bottomNavContentInset

    let top: CGFloat
    let horizontal: CGFloat
    let bottom: CGFloat?

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontal)
            .padding(.top, top)
            .padding(.bottom, bottom ?? bottomNavContentInset)
    }
}

extension View {
    func appScreenPadding(
        top: CGFloat = AppLayout.screenTopPadding,
        horizontal: CGFloat = AppLayout.screenHorizontalPadding,
        bottom: CGFloat? = nil
    ) -> some View {
        modifier(
            AppScreenPaddingModifier(
                top: top,
                horizontal: horizontal,
                bottom: bottom
            )
        )
    }
}
