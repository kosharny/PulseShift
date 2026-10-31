import XCTest
@testable import PulseShiftEnginePS

final class CampaignRevisionTestsPS: XCTestCase {
    func levels() throws -> [LevelPS] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try (1...6).flatMap { chapter in
            try JSONDecoder().decode([LevelPS].self, from: Data(contentsOf: root.appendingPathComponent(String(format: "Pulse Shift/Data/levels_chapter_%02d.json", chapter))))
        }
    }
    func testEveryHintUndoAndReplayMatchesDeterministicSolution() throws {
        for level in try levels() {
            let engine = GameEnginePS(level: level)
            for id in level.solutionMoves {
                XCTAssertEqual(engine.hint(), id, "Level \(level.id), move \(engine.state.moves)")
                let before = engine.state
                let first = engine.apply(.init(entityID: id))
                let after = engine.state
                XCTAssertTrue(first.accepted, "Level \(level.id), \(id)")
                engine.undo()
                XCTAssertEqual(engine.state, before)
                let replay = engine.apply(.init(entityID: id))
                XCTAssertEqual(engine.state, after)
                XCTAssertEqual(first.events.map(\.kind), replay.events.map(\.kind))
            }
            XCTAssertTrue(engine.completed, "Level \(level.id)")
            XCTAssertFalse(engine.failed)
        }
    }
    func testCampaignPacingAndDistinctLayouts() throws {
        let levels = try levels()
        XCTAssertEqual(levels.count, 60)
        XCTAssertTrue(levels.allSatisfy { $0.contentRevision == 2 && !($0.designIntent ?? "").isEmpty })
        XCTAssertEqual(Set(levels.map(\.name)).count, 60)
        XCTAssertEqual(Set(levels.map { String(describing: $0.entities) }).count, 60)
        XCTAssertGreaterThanOrEqual(Set(levels.map { "\($0.columns)×\($0.rows)" }).count, 6)
        XCTAssertTrue(levels.prefix(8).allSatisfy { $0.parMoves <= 4 })
        let late = levels.filter { $0.id >= 46 }
        XCTAssertGreaterThanOrEqual(Double(late.reduce(0) { $0 + $1.parMoves }) / Double(late.count), 7)
        var setups = 0
        for level in levels where level.id >= 16 {
            let engine = GameEnginePS(level: level)
            var hasSetup = false
            for id in level.solutionMoves {
                let result = engine.apply(.init(entityID: id))
                if !result.events.contains(where: { $0.kind == .exit }) { hasSetup = true }
            }
            if hasSetup { setups += 1 }
        }
        XCTAssertGreaterThanOrEqual(setups, 20)
    }
    func testFinalMoveCreatesMilestoneChainAndCompletesEveryObjective() throws {
        let level = try XCTUnwrap(levels().last)
        let engine = GameEnginePS(level: level)
        for id in level.solutionMoves.dropLast() { engine.apply(.init(entityID: id)) }
        XCTAssertFalse(engine.completed)
        XCTAssertEqual(engine.state.entities.filter { $0.kind == .dormant }.count, 6)
        let result = engine.apply(.init(entityID: try XCTUnwrap(level.solutionMoves.last)))
        XCTAssertTrue(result.completed)
        XCTAssertGreaterThanOrEqual(result.chain, 11)
        XCTAssertEqual(engine.state.portalsUsed.count, 2)
        XCTAssertTrue(level.entities.filter { $0.kind == .reactor }.allSatisfy { engine.state.activated.contains($0.id) })
    }
    func testPrematureCoreHasRecoverableUndo() throws {
        let level = try XCTUnwrap(levels().first { $0.id == 24 })
        let engine = GameEnginePS(level: level)
        let original = engine.state
        XCTAssertTrue(engine.apply(.init(entityID: "a")).accepted)
        XCTAssertFalse(engine.completed)
        engine.undo()
        XCTAssertEqual(engine.state, original)
        for id in level.solutionMoves { engine.apply(.init(entityID: id)) }
        XCTAssertTrue(engine.completed)
    }
    func testEventMetadataDistinguishesCrystalHitsAndGateStates() {
        let shard = LevelEntityPS(id: "a", kind: .shard, position: .init(row: 2, column: 0))
        let crystal = LevelEntityPS(id: "glass", kind: .crystal, position: .init(row: 2, column: 2), durability: 2)
        let level = LevelPS(id: 1, chapter: 1, name: "Metadata", rows: 5, columns: 5, parMoves: 3, entities: [shard, crystal], solutionMoves: ["a", "a", "a"])
        let engine = GameEnginePS(level: level)
        XCTAssertEqual(engine.apply(.init(entityID: "a")).events.first { $0.kind == .crystal }?.remainingDurability, 1)
        XCTAssertEqual(engine.apply(.init(entityID: "a")).events.first { $0.kind == .crystal }?.remainingDurability, 0)
    }
    func testHapticPatternsAreBoundedAndDistinct() {
        var signatures = Set<String>()
        for cue in HapticCuePS.allCases {
            XCTAssertFalse(cue.pulses.isEmpty)
            XCTAssertTrue(cue.pulses.allSatisfy { (0...1).contains($0.intensity) && (0...1).contains($0.sharpness) && (0...0.5).contains($0.time) })
            signatures.insert(cue.pulses.map { "\($0.time):\($0.intensity):\($0.sharpness)" }.joined())
        }
        XCTAssertEqual(signatures.count, HapticCuePS.allCases.count)
    }
    @MainActor func testRevisionRefreshesScoresWithoutChargingOrRepeatingRewards() {
        let persistence = PersistenceServicePS(inMemory: true)
        let old = GameResultPS(moves: 1, par: 1, chain: 1, seconds: 2, usedHint: false, usedUndo: false)
        persistence.record(key: "level-60", levelID: 60, result: old, reward: 10)
        let energy = persistence.player.energy
        let revised = GameResultPS(moves: 10, par: 10, chain: 11, seconds: 80, usedHint: false, usedUndo: false)
        XCTAssertEqual(persistence.record(key: "level-60", levelID: 60, result: revised, reward: 10, revision: 2), 0)
        XCTAssertEqual(persistence.player.energy, energy)
        XCTAssertEqual(persistence.records.first?.bestMoves, 10)
        XCTAssertEqual(persistence.records.first?.contentRevision, 2)
        XCTAssertEqual(persistence.records.first?.levelID, 60)
    }
}
