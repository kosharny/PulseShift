import SwiftUI
import Observation

enum AppTabPS: String, CaseIterable { case home = "Home", levels = "Levels", daily = "Daily", collection = "Collection"
    var symbol: String { switch self { case .home: "square.grid.2x2.fill"; case .levels: "square.stack.3d.up"; case .daily: "waveform.path"; case .collection: "circle.hexagongrid" } }
}
enum AppSheetPS: String, Identifiable { case settings, statistics, weekly, privacy, terms, debug
    var id: String { rawValue }
}
enum GameSessionStatePS { case loading, ready, playing, resolvingMove, paused, completed, failed, restarting }
enum PlayModePS: Equatable { case campaign, daily(String), weekly(String, Int) }

@MainActor @Observable final class PulseShiftViewModelPS {
    var tab: AppTabPS = .home
    var sheet: AppSheetPS?
    var selectedChapter: Int?
    var currentLevel: LevelPS?
    var sessionState: GameSessionStatePS = .ready
    var boardState = BoardStatePS(entities: [])
    var result: GameResultPS?
    var chain = 0
    var earnedEnergy = 0
    var hintMessage: String?
    var hintedID: String?
    var isLaunching = true
    var resetConfirmation: String?
    var now = Date()
    let catalog: LevelCatalogPS
    let persistence: PersistenceServicePS
    let settings: SettingsPS
    let gameCenter = GameCenterServicePS()
    let scene = GameScenePS(size: CGSize(width: 700, height: 900))
    let audio = AudioServicePS()
    let haptics = HapticServicePS()
    let dailyService = DailyChallengeServicePS()
    private let analytics = NoOpAnalyticsServicePS()
    private var engine: GameEnginePS?
    private var mode: PlayModePS = .campaign
    private var usedHint = false
    private var usedUndo = false
    private var tutorialFlow = false
    private var activeSince: Date?
    private var elapsed: TimeInterval = 0
    private var started = false
    var systemReduceMotion = false
    #if DEBUG
    var unlockAll = false
    var showFPS = false
    var showDebugLabels = false
    var debugMessage = ""
    #endif

    init(preview: Bool = false) {
        catalog = LevelCatalogPS()
        #if DEBUG
        let testing = ProcessInfo.processInfo.arguments.contains("--ps-ui-testing")
        let testURL = testing ? URL.documentsDirectory.appendingPathComponent("UITest.store") : nil
        persistence = PersistenceServicePS(inMemory: preview, storeURL: testURL)
        settings = SettingsPS(defaults: preview || testing ? UserDefaults(suiteName: testing ? "PulseShiftUITestsPS" : "PulseShiftPreviewPS") ?? .standard : .standard)
        if testing && ProcessInfo.processInfo.arguments.contains("--ps-reset") { persistence.resetProgress(); settings.launched = false; settings.themeID = "dark" }
        #else
        persistence = PersistenceServicePS(inMemory: preview)
        settings = SettingsPS(defaults: .standard)
        #endif
        if preview { isLaunching = false; started = true }
        scene.onTap = { [weak self] in self?.tap($0) }
        scene.onEvent = { [weak self] event, count in self?.feedback(event, chain: count) }

    }
    var theme: ThemePS { ThemePS.all.first { $0.id == settings.themeID } ?? ThemePS.all[0] }
    var campaignRecords: [LevelRecordPS] { persistence.records.filter { record in record.key.hasPrefix("level-") && record.contentRevision == (catalog.levels.first { $0.id == record.levelID }?.contentRevision ?? 1) } }
    var totalStars: Int { campaignRecords.reduce(0) { $0 + $1.stars } }
    var perfectClears: Int { campaignRecords.filter(\.perfect).count }
    var nextLevel: LevelPS? { catalog.levels.first { level in !campaignRecords.contains { $0.levelID == level.id } } ?? catalog.levels.last }
    var daily: DailyChallengePS? { dailyService.daily(date: now, levels: catalog.levels) }
    var dailyDays: Set<String> { Set(persistence.records.filter { $0.key.hasPrefix("daily-") }.map { String($0.key.dropFirst(6)) }) }
    var streak: Int { dailyService.streak(completedDays: dailyDays, today: now) }
    var weekKey: String { dailyService.weekKey(now) }
    var weeklyCompleted: Int { persistence.records.filter { $0.key.hasPrefix("weekly-\(weekKey)-") }.count }
    var canUndo: Bool { engine?.canUndo == true && sessionState != .resolvingMove }
    var isDailyMode: Bool { if case .daily = mode { true } else { false } }
    var chapter: ChapterPS { ChapterPS.all.first { $0.id == currentLevel?.chapter } ?? ChapterPS.all[0] }
    var reduced: Bool { settings.reducedEffects || systemReduceMotion }
    var achievements: [AchievementPS] {
        [
            .init(id: "firstpulse", title: "First Pulse", description: "Complete Level 1", symbol: "bolt.fill", value: record(1) == nil ? 0 : 1, target: 1),
            .init(id: "perfectsignal", title: "Perfect Signal", description: "Earn a Perfect Clear", symbol: "sparkles", value: perfectClears, target: 1),
            .init(id: "chainreaction", title: "Chain Reaction", description: "Reach Chain ×5", symbol: "point.3.connected.trianglepath.dotted", value: persistence.player.bestChain, target: 5),
            .init(id: "overload", title: "Overload", description: "Reach Chain ×10", symbol: "bolt.shield.fill", value: persistence.player.bestChain, target: 10),
            .init(id: "cleancircuit", title: "Clean Circuit", description: "Clear 10 levels without hints", symbol: "checkmark.seal", value: campaignRecords.filter(\.noHint).count, target: 10),
            .init(id: "polaritymaster", title: "Polarity Master", description: "Complete chapter 5", symbol: "plus.forwardslash.minus", value: campaignRecords.filter { (41...50).contains($0.levelID) }.count, target: 10),
            .init(id: "60hertz", title: "60 Hertz", description: "Complete all 60 levels", symbol: "waveform", value: campaignRecords.count, target: 60),
            .init(id: "dailyfrequency", title: "Daily Frequency", description: "Complete 7 Daily Shifts", symbol: "calendar", value: dailyDays.count, target: 7)
        ]
    }
    func record(_ id: Int) -> LevelRecordPS? { campaignRecords.first { $0.levelID == id } }
    func unlocked(_ id: Int) -> Bool {
        #if DEBUG
        if unlockAll { return true }
        #endif
        let legacyFrontier = (persistence.records.filter { $0.key.hasPrefix("level-") }.map(\.levelID).max() ?? 0) + 1
        return id <= max(nextLevel?.id ?? 1, legacyFrontier) || record(id) != nil
    }
    func chapterStars(_ id: Int) -> Int { campaignRecords.filter { ($0.levelID - 1) / 10 + 1 == id }.reduce(0) { $0 + $1.stars } }
    func startApp() async {
        guard !started else { return }; started = true
        persistence.player.sessions += 1; persistence.save()
        #if DEBUG
        if !ProcessInfo.processInfo.arguments.contains("--ps-ui-testing") { gameCenter.authenticate() }
        #else
        gameCenter.authenticate()
        #endif
        audio.setMusic(enabled: settings.music)
        analytics.track("game_started")
        try? await Task.sleep(for: .milliseconds(450))
        isLaunching = false
        audio.setSound(enabled: settings.sound)
        if !settings.launched {
            settings.launched = true; tutorialFlow = true
            if let first = catalog.levels.first { start(first) }
        }
        #if DEBUG
        if let value = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--ps-level=") }),
           let id = Int(value.replacingOccurrences(of: "--ps-level=", with: "")), let level = catalog.levels.first(where: { $0.id == id }) {
            tutorialFlow = false; start(level)
        }
        #endif
    }
    func start(_ level: LevelPS, mode: PlayModePS = .campaign) {
        haptics.prepare(enabled: settings.haptics)
        self.mode = mode; currentLevel = level; sheet = nil
        engine = GameEnginePS(level: level); boardState = BoardStatePS(entities: level.entities)
        result = nil; earnedEnergy = 0; usedHint = false; usedUndo = false; chain = 0; hintMessage = nil; hintedID = nil
        elapsed = 0; activeSince = .now; sessionState = .playing
        configureScene(animated: true)
        analytics.track("level_started", properties: ["level": "\(level.id)", "mode": "\(mode)"])
    }
    func startDaily() { if let daily { start(daily.level, mode: .daily(daily.key)) } }
    func startWeekly(_ stage: Int) {
        guard (0..<7).contains(stage), stage <= weeklyCompleted, !catalog.levels.isEmpty else { return }
        let seed = weekKey.utf8.reduce(0) { ($0 * 31 + Int($1)) % 1009 }
        let candidates = catalog.levels.filter { $0.chapter == min(6, stage + 1) }
        guard !candidates.isEmpty else { return }
        start(candidates[(seed + stage * 3) % candidates.count], mode: .weekly(weekKey, stage))
    }
    func tap(_ id: String) {
        guard sessionState == .playing, let engine else { return }
        haptics.play(HapticCuePS.tileTap, enabled: settings.haptics)
        audio.play(AudioCuePS.tap, enabled: settings.sound)
        let move = engine.apply(.init(entityID: id))
        if move.accepted { haptics.play(HapticCuePS.shift, enabled: settings.haptics); audio.play(AudioCuePS.whoosh, enabled: settings.sound) }
        sessionState = .resolvingMove; hintMessage = nil; hintedID = nil
        if move.accepted { persistence.player.totalMoves += 1; persistence.save() }
        boardState = engine.state; chain = 0
        scene.animate(move, finalState: engine.state) { [weak self] in self?.finishResolution() }
    }
    private func finishResolution() {
        guard let engine else { return }
        if engine.completed { complete() }
        else if engine.failed || !engine.hasAvailableMove { stopClock(); sessionState = .failed; analytics.track("level_failed") }
        else { sessionState = .playing }
        scene.reducedEffects = reduced
    }
    private func complete() {
        guard result == nil, let engine, let level = currentLevel else { return }
        stopClock()
        let result = GameResultPS(moves: engine.state.moves, par: level.parMoves, chain: engine.state.bestChain, seconds: Int(elapsed), usedHint: usedHint, usedUndo: usedUndo)
        self.result = result; sessionState = .completed
        let key: String; let reward: Int
        switch mode {
        case .campaign: key = "level-\(level.id)"; reward = 10
        case .daily(let day): key = "daily-\(day)"; reward = 75
        case .weekly(let week, let stage): key = "weekly-\(week)-\(stage)"; reward = stage == 6 ? 150 : 25
        }
        earnedEnergy = persistence.record(key: key, levelID: level.id, result: result, reward: reward, revision: level.contentRevision ?? 1)
        persistence.player.bestStreak = max(persistence.player.bestStreak, streak)
        let newlyUnlocked = achievements.filter { $0.unlocked && !persistence.player.unlockedAchievements.contains($0.id) }.map(\.id)
        persistence.player.unlockedAchievements.append(contentsOf: newlyUnlocked); persistence.save()
        Task { await gameCenter.report(achievementIDs: newlyUnlocked, perfectClears: perfectClears) }
        haptics.play(result.perfect ? HapticCuePS.perfect : .complete, enabled: settings.haptics)
        audio.play(result.perfect ? AudioCuePS.perfect : .victory, enabled: settings.sound)
        analytics.track("level_completed", properties: ["level": "\(level.id)", "moves": "\(result.moves)", "perfect": "\(result.perfect)"])
    }
    func next() {
        switch mode {
        case .campaign:
            if tutorialFlow, currentLevel?.id == 3 { tutorialFlow = false; home(); return }
            if let id = currentLevel?.id, let next = catalog.levels.first(where: { $0.id == id + 1 }) { start(next) } else { home() }
        case .daily: home(); tab = .daily
        case .weekly(let week, let stage): if week == weekKey, stage < 6 { startWeekly(stage + 1) } else { home(); sheet = .weekly }
        }
    }
    var nextLabel: String {
        switch mode { case .daily: "BACK TO DAILY"; case .weekly(_, let stage): stage < 6 ? "NEXT STAGE" : "CIRCUIT COMPLETE"; case .campaign: (tutorialFlow && currentLevel?.id == 3) || currentLevel?.id == 60 ? "BACK TO HOME" : "NEXT LEVEL" }
    }
    func restart() {
        guard let level = currentLevel else { return }
        persistence.player.restarts += 1; persistence.save(); analytics.track("level_restarted")
        start(level, mode: mode)
    }
    func undo() {
        guard canUndo, let engine else { return }
        engine.undo(); usedUndo = true; boardState = engine.state; result = nil; chain = 0
        sessionState = .playing; hintMessage = nil; hintedID = nil; if activeSince == nil { activeSince = .now }
        configureScene(animated: true); analytics.track("undo_used")
    }
    func hint() {
        guard sessionState == .playing, let engine else { return }
        usedHint = true; persistence.player.hints += 1; persistence.save()
        if let id = engine.hint() { hintedID = id; scene.highlight(id); hintMessage = "Try the highlighted signal." }
        else { hintMessage = "No clear route from here. Undo or restart to recover." }
        analytics.track("hint_used")
    }
    func pause() {
        guard sessionState == .playing || sessionState == .resolvingMove else { return }
        stopClock()
        if let engine { scene.settle(state: engine.state) }
        sessionState = .paused; audio.pause()
    }
    func resume() {
        guard sessionState == .paused else { return }
        activeSince = .now; audio.setMusic(enabled: settings.music)
        finishResolution()
    }
    func home() {
        stopClock(); if let engine { scene.settle(state: engine.state) }
        currentLevel = nil; engine = nil; result = nil; sessionState = .ready; tab = .home
    }
    func refresh() {
        now = .now
        applyAudioSettings()
        Task { await syncGameCenter() }
    }
    func openGameCenter() {
        gameCenter.open()
        if gameCenter.controller != nil { sheet = nil }
        Task { await syncGameCenter() }
    }
    func syncGameCenter() async {
        await gameCenter.report(achievementIDs: achievements.filter(\.unlocked).map(\.id), perfectClears: perfectClears)
    }
    func applyAudioSettings() {
        audio.setSound(enabled: settings.sound)
        audio.setMusic(enabled: settings.music && sessionState != .paused)
    }
    func applySceneSettings() {
        scene.reducedEffects = reduced
        if sessionState != .resolvingMove { configureScene() }
    }
    func applyTutorialSettings() {
        guard sessionState != .resolvingMove else { return }
        scene.clearHighlight()
        if hintMessage != nil {
            if let hintedID { scene.highlight(hintedID) }
        } else {
            hintedID = nil
            if settings.tutorialTips, boardState.moves == 0,
               currentLevel?.tutorialMessage != nil, let first = currentLevel?.solutionMoves.first {
                hintedID = first
                scene.highlight(first)
            }
        }
    }
    func configureScene(animated: Bool = false) {
        guard let level = currentLevel else { return }
        scene.reducedEffects = reduced
        #if DEBUG
        scene.debugLabels = showDebugLabels
        #endif
        scene.configure(level: level, state: boardState, theme: theme, animated: animated)
        applyTutorialSettings()
    }
    func owns(_ theme: ThemePS) -> Bool { persistence.player.unlockedThemes.contains(theme.id) }
    func rewardFeedback() {
        haptics.play(HapticCuePS.reward, enabled: settings.haptics)
        audio.play(AudioCuePS.reward, enabled: settings.sound)
    }
    func selectTheme(_ theme: ThemePS) {
        if !owns(theme) {
            guard persistence.player.energy >= theme.cost else { return }
            persistence.player.energy -= theme.cost; persistence.player.unlockedThemes.append(theme.id)
        }
        rewardFeedback()
        settings.themeID = theme.id; persistence.save(); analytics.track("theme_selected", properties: ["theme": theme.id])
    }
    func reset(_ kind: String) {
        if kind == "progress" { persistence.resetProgress(); settings.themeID = "dark"; settings.launched = false; home() }
        else { persistence.resetStatistics() }
        resetConfirmation = nil
    }
    func interfaceFeedback() {
        haptics.play(HapticCuePS.interfaceTap, enabled: settings.haptics)
        audio.play(AudioCuePS.tap, enabled: settings.sound)
    }
    private func feedback(_ event: GameEventPS, chain count: Int) {
        let kind = currentLevel?.entities.first { $0.id == event.entityID }?.kind
        let cue: HapticCuePS
        let sound: AudioCuePS
        switch event.kind {
        case .blocked: cue = .blocked; sound = .blocked
        case .crystal: cue = event.remainingDurability == 0 ? .crystalBreak : .crystalHit; sound = event.remainingDurability == 0 ? .crystalBreak : .crystalHit
        case .gate, .polarity, .magnet: cue = .gate; sound = .gate
        case .portal: cue = .portal; sound = .portal
        case .activate: cue = kind == .reactor || kind == .core ? .reactor : .gate; sound = .burst
        default: cue = .shift; sound = .spark
        }
        if count > chain && (count == 3 || count == 5 || count == 8 || count.isMultiple(of: 5)) {
            haptics.play(HapticCuePS.chain, enabled: settings.haptics); audio.play(AudioCuePS.combo, enabled: settings.sound)
        } else { haptics.play(cue, enabled: settings.haptics); audio.play(sound, enabled: settings.sound) }
        chain = count
    }
    private func stopClock() { if let activeSince { elapsed += Date().timeIntervalSince(activeSince); self.activeSince = nil } }
}
