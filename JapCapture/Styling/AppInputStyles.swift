//
//  AppInputStyles.swift
//  JapCapture
//
//  Created by Codex on 2026/4/15.
//

import SwiftUI

private enum AppInputMetrics {
    static let minHeight: CGFloat = 52
    static let horizontalPadding: CGFloat = 18
    static let verticalPadding: CGFloat = 14
    static let cornerRadius: CGFloat = 16
    static let fieldSpacing: CGFloat = 8
}

private struct AppInputFieldModifier: ViewModifier {
    let theme: AppTheme
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(AppTypography.bodyLarge)
            .foregroundStyle(theme.inputForeground)
            .padding(.horizontal, AppInputMetrics.horizontalPadding)
            .padding(.vertical, AppInputMetrics.verticalPadding)
            .frame(minHeight: AppInputMetrics.minHeight)
            .background(
                isFocused ? theme.inputFocusedFill : theme.inputFill,
                in: RoundedRectangle(
                    cornerRadius: AppInputMetrics.cornerRadius,
                    style: .continuous
                )
            )
    }
}

struct AppInputField<Content: View>: View {
    let isFocused: Bool
    let content: () -> Content

    private let theme = AppTheme()

    init(isFocused: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isFocused = isFocused
        self.content = content
    }

    var body: some View {
        content()
            .appInputField(theme: theme, isFocused: isFocused)
    }
}

struct AppInputHelperText: View {
    let text: String

    private let theme = AppTheme()

    var body: some View {
        Text(text)
            .font(AppTypography.labelSmall)
            .foregroundStyle(theme.inputHelperText)
    }
}

extension View {
    func appInputField(
        theme: AppTheme = AppTheme(),
        isFocused: Bool = false
    ) -> some View {
        modifier(AppInputFieldModifier(theme: theme, isFocused: isFocused))
    }
}
