import SwiftUI

struct LaunchAssembly: View {
    var onComplete: () -> Void

    @State private var animationToken = false
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false

    private let dotCount = 72
    private var background: Color { EmberColors.studioBackground }
    private var ember: Color { EmberColors.ember }
    private let muted = Color(hex: "2A2A2A")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background.ignoresSafeArea()

                if reducedMotionEnabled {
                    assembledDots(in: geo.size)
                } else {
                    KeyframeAnimator(
                        initialValue: LaunchAssemblyValues(),
                        trigger: animationToken
                    ) { values in
                        assembledDots(
                            in: geo.size,
                            ringProgress: values.ringProgress,
                            opacity: values.opacity,
                            scale: values.scale
                        )
                    } keyframes: { _ in
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0, duration: 0.08)
                            LinearKeyframe(1, duration: 0.24)
                            LinearKeyframe(1, duration: 0.64)
                        }

                        KeyframeTrack(\.ringProgress) {
                            LinearKeyframe(0, duration: 0.18)
                            CubicKeyframe(1, duration: 0.72)
                        }

                        KeyframeTrack(\.scale) {
                            LinearKeyframe(0.9, duration: 0.18)
                            SpringKeyframe(1, duration: 0.72, spring: .smooth)
                        }
                    }
                }
            }
        }
        .onAppear {
            if reducedMotionEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    onComplete()
                }
            } else {
                animationToken.toggle()
            }
        }
        .task(id: animationToken) {
            guard animationToken, !reducedMotionEnabled else { return }
            try? await Task.sleep(for: .seconds(1.08))
            onComplete()
        }
    }

    private func assembledDots(
        in size: CGSize,
        ringProgress: Double = 1,
        opacity: Double = 1,
        scale: Double = 1
    ) -> some View {
        let orbitSize = min(size.width, size.height) * 0.72
        let radius = orbitSize * 0.5
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        return ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                let ring = ringPoint(index: index, center: center, radius: radius)
                let scattered = scatteredPoint(index: index, in: size)
                let point = interpolatedPoint(from: scattered, to: ring, progress: ringProgress)
                let isMajor = index % 6 == 0
                let isAccent = index < dotCount / 3

                Circle()
                    .fill(isAccent ? ember : muted)
                    .frame(width: isMajor ? 7 : 5, height: isMajor ? 7 : 5)
                    .opacity(opacity * (isAccent ? 0.95 : 0.54))
                    .scaleEffect(scale)
                    .position(point)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func ringPoint(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) / Double(dotCount)) * 2 * Double.pi - Double.pi / 2
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }

    private func scatteredPoint(index: Int, in size: CGSize) -> CGPoint {
        let xSeed = sin(Double(index) * 12.9898) * 43758.5453
        let ySeed = cos(Double(index) * 78.233) * 24634.6345
        let xUnit = xSeed - floor(xSeed)
        let yUnit = ySeed - floor(ySeed)
        let inset: CGFloat = 42

        return CGPoint(
            x: inset + CGFloat(xUnit) * max(1, size.width - inset * 2),
            y: inset + CGFloat(yUnit) * max(1, size.height - inset * 2)
        )
    }

    private func interpolatedPoint(from start: CGPoint, to end: CGPoint, progress: Double) -> CGPoint {
        let eased = min(max(progress, 0), 1)
        return CGPoint(
            x: start.x + (end.x - start.x) * eased,
            y: start.y + (end.y - start.y) * eased
        )
    }
}

private struct LaunchAssemblyValues {
    var opacity = 0.0
    var ringProgress = 0.0
    var scale = 0.9
}

#Preview {
    LaunchAssembly {}
}
