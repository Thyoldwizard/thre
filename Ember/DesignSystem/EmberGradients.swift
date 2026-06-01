// EmberGradients.swift
import SwiftUI

struct EmberGradients {

    // MARK: - Card Gradients

    /// Default active task card — warm charcoal
    static let cardActive = LinearGradient(
        colors: [Color(hex: "1E1E22"), Color(hex: "1A1917")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Completed task card — subtle olive/amber shift
    static let cardCompleted = LinearGradient(
        colors: [Color(hex: "1A1D17"), Color(hex: "18170F")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card during long-press hold
    static let cardPressed = LinearGradient(
        colors: [Color(hex: "252528"), Color(hex: "22201C")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Button Gradients

    /// Primary CTA button — horizontal amber
    static let buttonPrimary = LinearGradient(
        colors: [EmberColors.accent, Color(hex: "D47A2E")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Button pressed state
    static let buttonPressed = LinearGradient(
        colors: [EmberColors.accentDark, Color(hex: "A85A18")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Ambient

    /// Subtle amber glow behind card stack on home screen
    static let ambientGlow = RadialGradient(
        colors: [
            EmberColors.emberGlow,
            Color.clear
        ],
        center: .center,
        startRadius: 20,
        endRadius: 300
    )

    // MARK: - Transcendence

    /// Full-screen golden glow for all-3-complete celebration
    static let transcendenceGlow = RadialGradient(
        colors: [
            EmberColors.accentLight.opacity(0.50),
            EmberColors.ember.opacity(0.25),
            Color.clear
        ],
        center: .center,
        startRadius: 10,
        endRadius: 400
    )

    // MARK: - Progress

    /// Long-press hold progress indicator fill
    static let progressFill = LinearGradient(
        colors: [EmberColors.accent, EmberColors.ember],
        startPoint: .leading,
        endPoint: .trailing
    )
}
