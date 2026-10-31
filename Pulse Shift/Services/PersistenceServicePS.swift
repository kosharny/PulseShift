import Foundation
import SwiftData
import Observation

@MainActor @Observable final class PersistenceServicePS {
    private(set) var container: ModelContainer?
    private(set) var records: [LevelRecordPS] = []
    private(set) var player = PlayerProgressPS()
    var errorMessage: String?
    init(inMemory: Bool = false, storeURL: URL? = nil) {
        do {
            let schema = Schema([LevelRecordPS.self, PlayerProgressPS.self])
            let configuration = storeURL.map { ModelConfiguration(schema: schema, url: $0) } ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: schema, configurations: [configuration])
            if let context = container?.mainContext {
                records = try context.fetch(FetchDescriptor<LevelRecordPS>())
                if let saved = try context.fetch(FetchDescriptor<PlayerProgressPS>()).first { player = saved }
                else { context.insert(player); try context.save() }
            }
        } catch { errorMessage = "Progress could not be loaded. This session remains playable. \(error.localizedDescription)" }
    }
    func save() {
        do { try container?.mainContext.save() }
        catch { errorMessage = "Your progress could not be saved. \(error.localizedDescription)" }
    }
    @discardableResult func record(key: String, levelID: Int, result: GameResultPS, reward: Int, date: Date = .now, revision: Int = 1) -> Int {
        var earned = 0
        if let record = records.first(where: { $0.key == key }) {
            if record.contentRevision != revision {
                record.stars = result.stars; record.bestMoves = result.moves
                record.perfect = result.perfect; record.noHint = !result.usedHint
                record.contentRevision = revision; record.completedAt = date
            } else {
            earned = max(0, result.stars - record.stars) * 5 + (result.perfect && !record.perfect ? 10 : 0)
            record.stars = max(record.stars, result.stars)
            record.bestMoves = min(record.bestMoves, result.moves)
            record.perfect = record.perfect || result.perfect
            record.noHint = record.noHint || !result.usedHint
            }
            if !key.hasPrefix("level-") { earned = 0 }
        } else {
            let record = LevelRecordPS(key: key, levelID: levelID, result: result, date: date)
            record.contentRevision = revision
            records.append(record); container?.mainContext.insert(record)
            earned = reward + result.stars * 5 + (result.perfect ? 10 : 0)
        }
        player.energy += earned
        player.bestChain = max(player.bestChain, result.chain)
        player.completions += 1; player.overPar += max(0, result.moves - result.par)
        save()
        return earned
    }
    func resetProgress() {
        for record in records { container?.mainContext.delete(record) }
        records = []
        container?.mainContext.delete(player)
        player = PlayerProgressPS(); container?.mainContext.insert(player); save()
    }
    func resetStatistics() {
        player.bestChain = 0; player.bestStreak = 0; player.totalMoves = 0; player.hints = 0
        player.restarts = 0; player.sessions = 0; player.completions = 0; player.overPar = 0; save()
    }
}

