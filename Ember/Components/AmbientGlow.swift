// AmbientGlow.swift
import SwiftUI

struct AmbientGlow: View {
    @State private var isAnimating = false

    /// Vertical offset from center — negative moves glow upward
    var verticalOffset: CGFloat = -60

    var body: some View {
        Circle()
            .fill(EmberGradients.ambientGlow)
            .frame(width: 400, height: 400)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 1.0 : 0.6)
            .blur(radius: 60)
            .offset(y: verticalOffset)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(EmberAnimation.glowPulse) {
                    isAnimating = true
                }
            }
    }
}
