// EmberViewTransitions.swift
// Shared reduced-motion-aware entrance treatment for route and cover changes.
import SwiftUI

private struct EmberRouteEntranceModifier: ViewModifier {
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false
    @State private var isVisible = false

    let edge: Edge
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: xOffset, y: yOffset)
            .scaleEffect(scale, anchor: anchor)
            .blur(radius: blurRadius)
            .onAppear {
                isVisible = false
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(activeAnimation) {
                        isVisible = true
                    }
                }
            }
    }

    private var activeAnimation: Animation {
        reducedMotionEnabled ? EmberAnimation.routeSettleReducedMotion : EmberAnimation.routeSettle
    }

    private var xOffset: CGFloat {
        guard !reducedMotionEnabled, !isVisible else { return 0 }
        switch edge {
        case .leading: return -distance
        case .trailing: return distance
        default: return 0
        }
    }

    private var yOffset: CGFloat {
        guard !reducedMotionEnabled, !isVisible else { return 0 }
        switch edge {
        case .top: return -distance
        case .bottom: return distance
        default: return 0
        }
    }

    private var scale: CGFloat {
        guard !reducedMotionEnabled, !isVisible else { return 1 }
        return 0.985
    }

    private var blurRadius: CGFloat {
        guard !reducedMotionEnabled, !isVisible else { return 0 }
        return 2
    }

    private var anchor: UnitPoint {
        switch edge {
        case .leading: return .leading
        case .trailing: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        }
    }
}

extension View {
    func emberRouteEntrance(edge: Edge = .trailing) -> some View {
        modifier(EmberRouteEntranceModifier(edge: edge, distance: 10))
    }

    func emberCoverEntrance(edge: Edge = .bottom) -> some View {
        modifier(EmberRouteEntranceModifier(edge: edge, distance: 14))
    }
}
