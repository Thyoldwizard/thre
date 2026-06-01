// AudioService.swift
// AVAudioEngine synthesis fallback — no .wav files required.
// Tones are generated programmatically from sine waves with exponential decay.
//
// Singing bowl : 220Hz + 440Hz + 660Hz harmonics, 2.0s exponential decay
// Harmonic tones: C4 (261.63Hz), E4 (329.63Hz), G4 (392Hz), 1.5s decay
// Let-go       : 440Hz + 220Hz soft chord, 1.5s decay
import AVFoundation

@MainActor
final class AudioService {
    static let shared = AudioService()

    // MARK: - Engine setup

    private let engine   = AVAudioEngine()
    private let mixer    = AVAudioMixerNode()
    private let format   = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    /// Pool of pre-attached player nodes for polyphonic playback
    private let playerPool: [AVAudioPlayerNode]
    private var poolIndex = 0

    private init() {
        // Pre-create 6 player slots for polyphonic output
        playerPool = (0..<6).map { _ in AVAudioPlayerNode() }

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        for player in playerPool {
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
        }

        engine.mainMixerNode.outputVolume = 0.85

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: .mixWithOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            EmberLogger.home.error("AudioService engine start failed", error)
        }
    }

    // MARK: - Public API

    func play(_ name: String) {
        guard EmberPreferences.soundEnabled else { return }

        switch name {
        case "singing-bowl":
            // 220Hz fundamental + 440Hz + 660Hz harmonics — singing bowl timbre
            playSine(frequencies: [220, 440, 660], duration: 2.0, volume: 0.38)

        case "harmonic-tone-1":
            // C4
            playSine(frequencies: [261.63], duration: 1.5, volume: 0.32)

        case "harmonic-tone-2":
            // E4
            playSine(frequencies: [329.63], duration: 1.5, volume: 0.32)

        case "harmonic-tone-3":
            // G4
            playSine(frequencies: [392.00], duration: 1.5, volume: 0.32)

        case "let-go":
            // Soft releasing chord — double octave
            playSine(frequencies: [440, 220], duration: 1.5, volume: 0.28)

        default:
            break
        }
    }

    func playTranscendenceChord() async {
        play("harmonic-tone-1")
        try? await Task.sleep(for: .seconds(0.4))
        play("harmonic-tone-2")
        try? await Task.sleep(for: .seconds(0.4))
        play("harmonic-tone-3")
    }

    // MARK: - Synthesis core

    private func playSine(frequencies: [Float], duration: Double, volume: Float) {
        guard let buffer = makeSineBuffer(
            frequencies: frequencies,
            duration: duration,
            volume: volume
        ) else { return }

        let player = nextPlayer()

        // Stop any currently-playing buffer on this node so new tones don't stack awkwardly
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Builds a PCM buffer filled with a sum of sine waves with exponential amplitude decay.
    private func makeSineBuffer(
        frequencies: [Float],
        duration: Double,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        let sampleRate  = Float(format.sampleRate)
        let frameCount  = AVAudioFrameCount(sampleRate * Float(duration))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        // decay constant: amplitude reaches ~1/e^4 ≈ 1.8% by end of duration
        let decayK = Float(4.0 / duration)

        for frame in 0..<Int(frameCount) {
            let t         = Float(frame) / sampleRate
            let envelope  = expf(-decayK * t)
            var sample: Float = 0

            for freq in frequencies {
                sample += sinf(2 * .pi * freq * t)
            }

            // Normalise by frequency count, apply envelope and volume
            channelData[frame] = (sample / Float(frequencies.count)) * envelope * volume
        }

        return buffer
    }

    // MARK: - Node pool

    private func nextPlayer() -> AVAudioPlayerNode {
        let player = playerPool[poolIndex]
        poolIndex = (poolIndex + 1) % playerPool.count
        return player
    }
}
