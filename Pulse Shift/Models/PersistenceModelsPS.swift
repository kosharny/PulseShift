import Foundation
import SwiftData

@Model final class LevelRecordPS {
    @Attribute(.unique) var key: String
    var levelID: Int
    var stars: Int
    var bestMoves: Int
    var perfect: Bool
    var noHint: Bool
    var contentRevision: Int = 1
    var completedAt: Date
    init(key: String, levelID: Int, result: GameResultPS, date: Date = .now) {
        self.key = key; self.levelID = levelID; stars = result.stars; bestMoves = result.moves
        perfect = result.perfect; noHint = !result.usedHint; completedAt = date
    }
}

@Model final class PlayerProgressPS {
    @Attribute(.unique) var id: String
    var energy: Int
    var bestChain: Int
    var bestStreak: Int
    var totalMoves: Int
    var hints: Int
    var restarts: Int
    var sessions: Int
    var completions: Int
    var overPar: Int
    var unlockedThemes: [String]
    var unlockedAchievements: [String]
    init() {
        id = "player"; energy = 0; bestChain = 0; bestStreak = 0; totalMoves = 0
        hints = 0; restarts = 0; sessions = 0; completions = 0; overPar = 0
        unlockedThemes = ["dark"]; unlockedAchievements = []
    }
}

