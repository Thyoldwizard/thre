// GlassCardModifier.swift
import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = EmberCornerRadii.card

    func body(content: Content) -> some View {
        content
            .padding(EmberSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(EmberColors.cardSurface.opacity(0.70))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            }
            .overlay {
                // Glass stroke border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(EmberColors.glassStroke, lineWidth: 1)
            }
            .overlay(alignment: .top) {
                // Top-edge inner highlight
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [EmberColors.glassHighlight, Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: EmberShadows.card.color,
                radius: EmberShadows.card.radius,
                x: EmberShadows.card.x,
                y: EmberShadows.card.y
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = EmberCornerRadii.card) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
