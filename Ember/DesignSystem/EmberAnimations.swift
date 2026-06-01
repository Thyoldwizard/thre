// EmberAnimations.swift
import SwiftUI

struct EmberAnimation {

    // MARK: - System spring presets (iOS 17+)
    // Named tokens wrapping the three SwiftUI built-in spring presets.
    // Prefer these over ad-hoc .spring(response:dampingFraction:) calls.

    /// Playful spring with gentle overshoot — use for UI elements that benefit from energy
    static let bouncy: Animation = .bouncy

    /// Quick, decisive spring with minimal overshoot — use for state chips and toggles
    static let snappy: Animation = .snappy

    /// Soft, damped spring — use for panels and large surfaces
    static let smooth: Animation = .smooth

    // MARK: - Card Animations

    /// Card entrance on home screen — organic spring
    static let cardAppear: Animation = .spring(response: 0.6, dampingFraction: 0.8)

    /// Card entrance using bouncy preset
    static let cardAppearBouncy: Animation = .bouncy

    /// Card scale-down on press start
    static let cardPress: Animation = .spring(response: 0.3, dampingFraction: 0.9)

    /// Card bounce-back on press release
    static let cardRelease: Animation = .spring(response: 0.5, dampingFraction: 0.7)

    // MARK: - Completion

    /// Task completion release — slow exhale feel
    static let completionExhale: Animation = .spring(response: 0.8, dampingFraction: 0.6)

    // MARK: - Subtask

    /// Subtask checkbox toggle
    static let subtaskCheck: Animation = .spring(response: 0.4, dampingFraction: 0.75)

    // MARK: - Sheet

    /// Bottom sheet presentation
    static let sheetPresent: Animation = .spring(response: 0.5, dampingFraction: 0.85)

    /// Bottom sheet dismissal
    static let sheetDismiss: Animation = .snappy

    // MARK: - Route Transitions

    /// Subtle navigation settle for pushed screens and full-screen covers.
    static let routeSettle: Animation = .spring(response: 0.34, dampingFraction: 0.9)

    /// Reduced-motion route transition keeps spatial travel out of the path.
    static let routeSettleReducedMotion: Animation = .smooth(duration: 0.16)

    // MARK: - Fade

    /// Generic fade in
    static let fadeIn: Animation = .smooth

    /// Generic fade out
    static let fadeOut: Animation = .smooth.speed(1.4)

    // MARK: - Ambient

    /// Glow breathing cycle — slow, meditative
    static let glowPulse: Animation = .smooth(duration: 4.0).repeatForever(autoreverses: true)

    // MARK: - Transcendence

    /// Transcendence view entrance — grand, slow spring
    static let transcendenceIn: Animation = .spring(response: 1.0, dampingFraction: 0.6)

    // MARK: - Stagger

    /// Per-item stagger delay for sequential animations
    static let staggerDelay: TimeInterval = 0.08

    /// Convenience: returns a cardAppear animation delayed by index * staggerDelay
    static func staggeredCardAppear(index: Int) -> Animation {
        cardAppear.delay(Double(index) * staggerDelay)
    }
}

// MARK: - Shared button style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(EmberAnimation.cardPress, value: configuration.isPressed)
    }
}
