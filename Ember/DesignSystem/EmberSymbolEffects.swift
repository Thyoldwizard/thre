// EmberSymbolEffects.swift
import SwiftUI

private struct EmberSymbolEffectsReducedMotionModifier: ViewModifier {
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false

    func body(content: Content) -> some View {
        content.symbolEffectsRemoved(reducedMotionEnabled)
    }
}

extension View {
    func emberSymbolEffectsRespectReducedMotion() -> some View {
        modifier(EmberSymbolEffectsReducedMotionModifier())
    }

    func completeBounce<Value: Equatable>(_ trigger: Value) -> some View {
        symbolEffect(.bounce, value: trigger)
            .emberSymbolEffectsRespectReducedMotion()
    }

    func toastPulse(_ isActive: Bool = true) -> some View {
        symbolEffect(.pulse, options: .repeating, isActive: isActive)
            .emberSymbolEffectsRespectReducedMotion()
    }

    func replaceCheck(_ isChecked: Bool) -> some View {
        contentTransition(.symbolEffect(.replace))
            .completeBounce(isChecked)
    }
}
