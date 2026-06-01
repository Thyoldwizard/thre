// EmberButton.swift
import SwiftUI

struct EmberButton: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(EmberTypography.button)
                .tracking(EmberTypography.Tracking.widest)
                .foregroundStyle(EmberColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.medium, style: .continuous)
                        .fill(isPressed ? EmberGradients.buttonPressed : EmberGradients.buttonPrimary)
                )
                .emberShadow(EmberShadows.button)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(EmberAnimation.cardPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
