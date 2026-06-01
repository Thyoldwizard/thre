// StreakBadge.swift
import SwiftUI

struct StreakBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: EmberSpacing.xs) {
            ZStack {
                Circle()
                    .strokeBorder(EmberColors.ember.opacity(0.22), lineWidth: 1)
                    .frame(width: 17, height: 17)

                Circle()
                    .fill(EmberColors.ember)
                    .frame(width: 6, height: 6)
            }

            Text("\(count)")
                .font(EmberTypography.streakCount)
                .foregroundStyle(EmberColors.textPrimary)
        }
        .padding(.horizontal, EmberSpacing.sm)
        .padding(.vertical, EmberSpacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(EmberColors.cardSurface.opacity(0.6))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(EmberColors.glassStroke, lineWidth: 1)
                )
        )
        .emberShadow(EmberShadows.subtle)
        .accessibilityLabel("Current streak: \(count) days")
    }
}
