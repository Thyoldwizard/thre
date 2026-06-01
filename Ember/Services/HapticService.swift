// HapticService.swift
import CoreHaptics
import UIKit

@MainActor
final class HapticService {
    static let shared = HapticService()

    private var engine: CHHapticEngine?
    private var lastEscalatingHoldTapAt: Date?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            EmberLogger.home.error("Haptic engine failed", error)
        }

        engine?.stoppedHandler = { [weak self] reason in
            EmberLogger.home.debug("Haptic engine stopped: \(reason)")
            Task { @MainActor [weak self] in try? self?.engine?.start() }
        }
        engine?.resetHandler = { [weak self] in
            Task { @MainActor [weak self] in try? self?.engine?.start() }
        }
    }

    // MARK: - Heartbeat (double-tap)

    func playHeartbeat() {
        guard EmberPreferences.hapticsEnabled else { return }
        guard let engine else { return }

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.15
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            EmberLogger.home.error("Haptic playback failed", error)
        }
    }

    // MARK: - Gentle continuous (during hold)

    func playGentleContinuous(duration: TimeInterval) {
        guard EmberPreferences.hapticsEnabled else { return }
        guard let engine else { return }

        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: duration
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            EmberLogger.home.error("Haptic playback failed", error)
        }
    }

    // MARK: - Escalating hold cadence

    func playEscalatingHoldCadence(progress: CGFloat) {
        guard EmberPreferences.hapticsEnabled else { return }

        let now = Date()
        let interval = Self.escalatingHoldCadenceInterval(for: progress)
        if let lastEscalatingHoldTapAt,
           now.timeIntervalSince(lastEscalatingHoldTapAt) < interval {
            return
        }

        lastEscalatingHoldTapAt = now
        let style: UIImpactFeedbackGenerator.FeedbackStyle = progress >= 0.85 ? .rigid : .light
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: min(1, 0.35 + progress * 0.65))
    }

    nonisolated static func escalatingHoldCadenceInterval(for progress: CGFloat) -> TimeInterval {
        progress >= 0.85 ? 0.08 : 0.25
    }

    // MARK: - Completion burst

    func playCompletionBurst() {
        guard EmberPreferences.hapticsEnabled else { return }
        guard let engine else { return }

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.1
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.25
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            EmberLogger.home.error("Haptic playback failed", error)
        }
    }
}
