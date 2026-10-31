import CoreHaptics
import AVFAudio
#if canImport(UIKit)
import UIKit
#endif

enum HapticCuePS: String, CaseIterable {
    case tileTap, shift, blocked, crystalHit, crystalBreak, gate, portal, reactor, chain, complete, perfect, reward, interfaceTap
    var pulses: [(time: Double, intensity: Float, sharpness: Float)] {
        switch self {
        case .tileTap: [(0, 0.55, 0.8)]
        case .shift: [(0.025, 0.4, 0.5)]
        case .blocked: [(0, 0.65, 0.12), (0.08, 0.3, 0.1)]
        case .crystalHit: [(0, 0.65, 0.9)]
        case .crystalBreak: [(0, 0.9, 1), (0.065, 0.4, 0.8)]
        case .gate: [(0, 0.55, 0.45), (0.07, 0.75, 0.65)]
        case .portal: [(0, 0.3, 0.2), (0.08, 0.55, 0.5), (0.17, 0.8, 0.85)]
        case .reactor: [(0, 0.3, 0.2), (0.06, 0.5, 0.35), (0.14, 0.95, 0.85)]
        case .chain: [(0, 0.75, 0.75), (0.07, 0.95, 0.95)]
        case .complete: [(0, 0.65, 0.6), (0.12, 0.85, 0.8), (0.26, 1, 0.9)]
        case .perfect: [(0, 0.6, 0.5), (0.09, 0.75, 0.7), (0.19, 0.9, 0.8), (0.34, 1, 1)]
        case .reward: [(0, 0.5, 0.85), (0.07, 0.65, 1)]
        case .interfaceTap: [(0, 0.25, 0.6)]
        }
    }
}

@MainActor final class HapticServicePS {
    private var engine: CHHapticEngine?
    private var players: [CHHapticPatternPlayer] = []
    private var lastCue: HapticCuePS?
    private var lastTime = Date.distantPast
    #if canImport(UIKit)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let impact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    #endif

    func prepare(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        soft.prepare(); impact.prepare(); notification.prepare()
        #endif
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do { try startEngine() } catch { engine = nil }
    }
    private func startEngine() throws {
        if engine == nil {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in Task { @MainActor [weak self] in self?.engine = nil; self?.players.removeAll() } }
            self.engine = engine
        }
        try engine?.start()
    }
    func play(_ cue: HapticCuePS, enabled: Bool) {
        guard enabled else { return }
        let now = Date()
        guard cue != lastCue || now.timeIntervalSince(lastTime) > 0.055 else { return }
        lastCue = cue; lastTime = now
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { fallback(cue); return }
        do {
            try startEngine()
            let events = cue.pulses.map { pulse in
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: pulse.intensity),
                    .init(parameterID: .hapticSharpness, value: pulse.sharpness)
                ], relativeTime: pulse.time)
            }
            if let player = try engine?.makePlayer(with: CHHapticPattern(events: events, parameters: [])) {
                players.append(player)
                if players.count > 8 { players.removeFirst() }
                try player.start(atTime: CHHapticTimeImmediate)
            }
        } catch { engine = nil; players.removeAll(); fallback(cue) }
    }
    func play(_ kind: GameEventKindPS, enabled: Bool, strength: Float = 0.45) {
        let cue: HapticCuePS
        switch kind {
        case .blocked: cue = .blocked
        case .crystal: cue = .crystalBreak
        case .gate: cue = .gate
        case .portal: cue = .portal
        case .activate, .pulse: cue = .reactor
        case .polarity, .magnet: cue = .gate
        default: cue = .shift
        }
        play(cue, enabled: enabled)
    }
    private func fallback(_ cue: HapticCuePS) {
        #if canImport(UIKit)
        switch cue {
        case .complete, .perfect: notification.notificationOccurred(.success)
        case .blocked: notification.notificationOccurred(.warning)
        case .tileTap, .shift, .interfaceTap: soft.impactOccurred(intensity: cue == .interfaceTap ? 0.35 : 0.7)
        default: impact.impactOccurred(intensity: 0.85)
        }
        #endif
    }
}

enum AudioCuePS: String, CaseIterable {
    case tap, whoosh, blocked, spark, gate, portal, burst, crystalHit, crystalBreak, combo, reward, victory, perfect
}

@MainActor final class AudioServicePS {
    private let playback = AudioPlaybackPS()

    func play(_ cue: AudioCuePS, enabled: Bool) { playback.play(cue.rawValue, enabled: enabled) }
    func play(_ name: String, enabled: Bool) { playback.play(name, enabled: enabled) }
    func setSound(enabled: Bool) { playback.setSound(enabled: enabled) }
    func setMusic(enabled: Bool) { playback.setMusic(enabled: enabled) }
    func pause() { playback.pause() }
}

// AVAudioPlayer and audio session state are confined to the serial playback queue.
private final class AudioPlaybackPS: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.pulseshift.audio", qos: .userInitiated)
    private var players: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var soundEnabled = true

    init() {
        #if os(iOS)
        queue.async {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient)
            try? session.setActive(true)
        }
        #endif
    }

    func setSound(enabled: Bool) {
        queue.async { [self] in
            soundEnabled = enabled
            if !enabled { players.values.forEach { $0.stop() } }
        }
    }

    func play(_ name: String, enabled: Bool) {
        guard enabled else { return }
        queue.async { [self] in
            guard soundEnabled else { return }
            do {
                if players[name] == nil, let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                    players[name] = try AVAudioPlayer(contentsOf: url)
                    players[name]?.prepareToPlay()
                }
                players[name]?.currentTime = 0
                players[name]?.play()
            } catch { players[name] = nil }
        }
    }

    func setMusic(enabled: Bool) {
        queue.async { [self] in
            guard enabled else { musicPlayer?.pause(); return }
            if musicPlayer == nil, let url = Bundle.main.url(forResource: "ambient", withExtension: "wav") {
                musicPlayer = try? AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1
                musicPlayer?.volume = 0.25
                musicPlayer?.prepareToPlay()
            }
            if musicPlayer?.isPlaying == false { musicPlayer?.play() }
        }
    }

    func pause() {
        queue.async { [self] in
            players.values.forEach { $0.stop() }
            musicPlayer?.pause()
        }
    }
}

protocol AnalyticsServicePS { func track(_ event: String, properties: [String: String]) }
struct NoOpAnalyticsServicePS: AnalyticsServicePS { func track(_ event: String, properties: [String: String] = [:]) {} }
protocol AdServicePS {
    func showRewardedHint() async -> Bool
    func showRewardedUndo() async -> Bool
    func showRewardedContinue() async -> Bool
    func showInterstitialIfEligible() async
}
struct MockAdServicePS: AdServicePS {
    var simulateSuccess = false
    func showRewardedHint() async -> Bool { simulateSuccess }
    func showRewardedUndo() async -> Bool { simulateSuccess }
    func showRewardedContinue() async -> Bool { simulateSuccess }
    func showInterstitialIfEligible() async {}
}
