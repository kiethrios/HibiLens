//
//  AppTypography.swift
//  JapCapture
//
//  Created by Codex on 2026/4/14.
//

import AppFamilyDesign
import SwiftUI

enum AppTypography {
    // MARK: Semantic type roles

    static let japaneseHero = FamilyTypography.contentHero
    static let japaneseCardTitle = FamilyTypography.contentCardTitle
    static let japaneseSupport = FamilyTypography.contentSupport
    static let romajiHelper = FamilyTypography.transliterationHelper
    static let translationMetadata = FamilyTypography.metadata
    static let bodyDefinition = FamilyTypography.definition
    static let actionPrimary = FamilyTypography.actionPrimary
    static let sectionTitle = FamilyTypography.sectionTitle
    static let sectionLabel = FamilyTypography.sectionLabel
    static let metricNumber = FamilyTypography.metricNumber

    static let displayLarge = FamilyTypography.displayLarge
    static let displayMedium = FamilyTypography.displayMedium
    static let displaySmall = FamilyTypography.displaySmall
    static let displayXLarge = FamilyTypography.displayXLarge

    static let headlineLarge = FamilyTypography.headlineLarge
    static let headlineMedium = FamilyTypography.headlineMedium
    static let headlineSmall = FamilyTypography.headlineSmall

    static let titleLarge = FamilyTypography.titleLarge
    static let titleMedium = FamilyTypography.titleMedium
    static let titleSmall = FamilyTypography.titleSmall

    static let bodyLarge = FamilyTypography.bodyLarge
    static let bodyMedium = FamilyTypography.bodyMedium
    static let bodySmall = FamilyTypography.bodySmall

    static let labelMedium = FamilyTypography.labelMedium
    static let labelSmall = FamilyTypography.labelSmall
    static let labelXSmall = FamilyTypography.labelXSmall

    // MARK: Tracking

    static let displayTracking = FamilyTypography.displayTracking
    static let displayHeroTracking = FamilyTypography.displayHeroTracking
    static let displayMetricTracking = FamilyTypography.displayMetricTracking
    static let headlineTracking = FamilyTypography.headlineTracking
    static let labelTracking = FamilyTypography.labelTracking
    static let eyebrowTracking = FamilyTypography.eyebrowTracking
    static let sectionLabelTracking = FamilyTypography.sectionLabelTracking

    // MARK: Japanese line height policy

    static let japaneseLineHeightMinMultiplier = FamilyTypography.contentLineHeightMinMultiplier
    static let japaneseLineHeightMaxMultiplier = FamilyTypography.contentLineHeightMaxMultiplier
    static let japaneseLineHeightDefaultMultiplier = FamilyTypography.contentLineHeightDefaultMultiplier

    static func lineSpacing(
        for fontSize: CGFloat,
        multiplier: CGFloat = japaneseLineHeightDefaultMultiplier
    ) -> CGFloat {
        FamilyTypography.contentLineSpacing(
            for: fontSize,
            multiplier: multiplier
        )
    }
}

extension View {
    func appJapaneseLineHeight(
        fontSize: CGFloat,
        multiplier: CGFloat = AppTypography.japaneseLineHeightDefaultMultiplier
    ) -> some View {
        lineSpacing(AppTypography.lineSpacing(for: fontSize, multiplier: multiplier))
    }
}
