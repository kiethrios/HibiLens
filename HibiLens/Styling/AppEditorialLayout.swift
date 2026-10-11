import SwiftUI

struct AppEditorialSectionLabel: View {
    let theme: AppTheme
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(AppTypography.labelSmall.weight(.bold))
            .tracking(AppTypography.sectionLabelTracking)
            .foregroundStyle(theme.tertiary)
    }
}

struct AppEditorialHeader: View {
    let theme: AppTheme
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        theme: AppTheme,
        title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.theme = theme
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        if let actionTitle, let action {
            HStack(alignment: .top, spacing: AppLayout.editorialHeaderOffset) {
                titleView

                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.top, AppLayout.editorialHeaderMetricDrop)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppLayout.editorialSectionInnerGutter)
        } else {
            titleView
                .padding(.horizontal, AppLayout.editorialSectionInnerGutter)
        }
    }

    private var titleView: some View {
        Text(title)
            .font(AppTypography.headlineLarge)
            .tracking(AppTypography.headlineTracking)
            .foregroundStyle(theme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
