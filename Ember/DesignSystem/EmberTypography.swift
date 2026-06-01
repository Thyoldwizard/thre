// EmberTypography.swift
import SwiftUI

struct EmberTypography {

    // MARK: - Hero

    /// Signature hero numerals — SF Pro thin/light, shared by orbit, streak, and completion.
    static let heroNumeral: Font = .system(size: 96, weight: .thin, design: .default).monospacedDigit()

    /// Daily Orbit value — compact version of the signature numeral.
    static let orbitHero: Font = .system(size: 58, weight: .light, design: .default).monospacedDigit()

    // MARK: - Display / Headings

    /// Large screen statement/title.
    static let heroHeadline: Font = .system(size: 40, weight: .bold, design: .default)

    /// Screen title.
    static let largeTitle: Font = .system(size: 32, weight: .bold, design: .default)

    /// Section titles.
    static let title: Font = .system(size: 28, weight: .bold, design: .default)

    /// Task card title.
    static let taskTitle: Font = .system(size: 20, weight: .semibold, design: .default)

    // MARK: - SF Pro (System — Body & UI)

    /// Body text — 16pt SF Pro Regular
    static let body: Font = .system(size: 16, weight: .regular, design: .default)

    /// Emphasized body — 16pt SF Pro Medium
    static let bodyMedium: Font = .system(size: 16, weight: .medium, design: .default)

    /// Caption text — 13pt SF Pro Regular
    static let caption: Font = .system(size: 13, weight: .regular, design: .default)

    /// Emphasized caption — 13pt SF Pro Medium
    static let captionMedium: Font = .system(size: 13, weight: .medium, design: .default)

    /// Tiny labels — 11pt SF Pro Regular
    static let small: Font = .system(size: 11, weight: .regular, design: .default)

    /// Tracked section label — 11pt SF Pro Semibold
    static let sectionLabel: Font = .system(size: 11, weight: .semibold, design: .default)

    // MARK: - SF Pro Rounded (Buttons & Numbers)

    /// Button labels — 16pt SF Pro Semibold
    static let button: Font = .system(size: 16, weight: .semibold, design: .default)

    /// Streak count — signature numeral treatment.
    static let streakCount: Font = heroNumeral

    // MARK: - Tracking (Letter Spacing)

    struct Tracking {
        static let tight: CGFloat    = 0
        static let snug: CGFloat     = 0
        static let normal: CGFloat   = 0
        static let wide: CGFloat     = 0.2
        static let wider: CGFloat    = 1.4
        static let widest: CGFloat   = 3.0
    }

    // MARK: - Line Spacing

    struct LineSpacing {
        static let tight: CGFloat   = 0.15 // multiplier: 1.15x at 34pt ≈ 5pt extra
        static let snug: CGFloat    = 0.2  // multiplier: 1.2x
        static let normal: CGFloat  = 0.25 // multiplier: 1.25x
        static let relaxed: CGFloat = 0.5  // multiplier: 1.5x
    }
}

// MARK: - Convenience View Modifiers

extension View {
    /// Apply Ember large title style (date header)
    func emberLargeTitle() -> some View {
        self
            .font(EmberTypography.largeTitle)
            .tracking(EmberTypography.Tracking.tight)
            .foregroundStyle(EmberColors.textPrimary)
    }

    /// Apply Ember title style
    func emberTitle() -> some View {
        self
            .font(EmberTypography.title)
            .tracking(EmberTypography.Tracking.snug)
            .foregroundStyle(EmberColors.textPrimary)
    }

    /// Apply Ember task title style
    func emberTaskTitle() -> some View {
        self
            .font(EmberTypography.taskTitle)
            .tracking(EmberTypography.Tracking.normal)
            .foregroundStyle(EmberColors.textPrimary)
    }

    /// Apply Ember body style
    func emberBody() -> some View {
        self
            .font(EmberTypography.body)
            .foregroundStyle(EmberColors.textPrimary)
    }

    /// Apply Ember caption style
    func emberCaption() -> some View {
        self
            .font(EmberTypography.caption)
            .tracking(EmberTypography.Tracking.wide)
            .foregroundStyle(EmberColors.textSecondary)
    }

    /// Apply Ember button label style
    func emberButtonLabel() -> some View {
        self
            .font(EmberTypography.button)
            .tracking(EmberTypography.Tracking.normal)
            .foregroundStyle(EmberColors.textPrimary)
    }

    /// Apply Ember section label style.
    func emberSectionLabel() -> some View {
        self
            .font(EmberTypography.sectionLabel)
            .tracking(EmberTypography.Tracking.widest)
            .foregroundStyle(EmberColors.textSecondary)
    }
}
