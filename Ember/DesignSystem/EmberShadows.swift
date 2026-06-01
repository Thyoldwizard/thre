// EmberShadows.swift
import SwiftUI

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

struct EmberShadows {

    /// Default task card
    static let card = ShadowStyle(
        color: Color.black.opacity(0.25),
        radius: 16,
        x: 0,
        y: 8
    )

    /// Elevated card (during press or drag)
    static let cardElevated = ShadowStyle(
        color: Color.black.opacity(0.35),
        radius: 24,
        x: 0,
        y: 12
    )

    /// CTA button
    static let button = ShadowStyle(
        color: Color.black.opacity(0.30),
        radius: 12,
        x: 0,
        y: 6
    )

    /// Ambient ember glow
    static let glow = ShadowStyle(
        color: EmberColors.emberGlow,
        radius: 24,
        x: 0,
        y: 0
    )

    /// Subtle elevation for badges, chips
    static let subtle = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )

    /// Explicit no shadow
    static let none = ShadowStyle(
        color: Color.clear,
        radius: 0,
        x: 0,
        y: 0
    )
}

// MARK: - View Extension

extension View {
    func emberShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
