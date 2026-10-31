import XCTest
@testable import PulseShiftEnginePS

final class GameEngineTestsPS: XCTestCase {
    func testEveryBundledSolution() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        var total = 0
        for chapter in 1...6 {
            let url = root.appendingPathComponent(String(format: "Pulse Shift/Data/levels_chapter_%02d.json", chapter))
            let levels = try JSONDecoder().decode([LevelPS].self, from: Data(contentsOf: url))
            total += levels.count
            for level in levels { XCTAssertEqual(LevelValidatorPS.errors(in: level), [], "Level \(level.id)") }
        }
        XCTAssertEqual(total, 60)
    }
    func make(_ entities: [LevelEntityPS], max: Int? = nil) -> GameEnginePS {
        .init(level: .init(id: 1, chapter: 1, name: "Test", rows: 7, columns: 7, parMoves: 3, maxMoves: max, entities: entities, solutionMoves: ["s"]))
    }
    func shard(_ id: String = "s", _ row: Int = 3, _ column: Int = 1, _ direction: DirectionPS = .right) -> LevelEntityPS {
        .init(id: id, kind: .shard, position: .init(row: row, column: column), direction: direction)
    }
    func testStandardClearAndUndoAndRestart() {
        let engine = make([shard()]); let initial = engine.state
        XCTAssertTrue(engine.apply(.init(entityID: "s")).completed)
        XCTAssertEqual(engine.state.moves, 1)
        engine.undo(); XCTAssertEqual(engine.state, initial)
        engine.apply(.init(entityID: "s")); engine.restart(); XCTAssertEqual(engine.state, initial)
    }
    func testBlockedMoveIsFree() {
        let engine = make([shard(), .init(id: "w", kind: .wall, position: .init(row: 3, column: 2))])
        XCTAssertFalse(engine.apply(.init(entityID: "s")).accepted)
        XCTAssertEqual(engine.state.moves, 0)
    }
    func testRedirectorAndRotator() {
        for kind in [EntityKindPS.redirector, .rotator] {
            let engine = make([shard(), .init(id: "r", kind: kind, position: .init(row: 3, column: 3), turns: -1)])
            let result = engine.apply(.init(entityID: "s"))
            XCTAssertTrue(result.completed)
            XCTAssertEqual(result.events.last?.to, .init(row: -1, column: 3))
        }
    }
    func testPortalRotation() {
        let engine = make([shard(), .init(id: "a", kind: .portal, position: .init(row: 3, column: 3), turns: 1, pair: "p"), .init(id: "b", kind: .portal, position: .init(row: 1, column: 5), pair: "p")])
        let result = engine.apply(.init(entityID: "s"))
        XCTAssertTrue(result.completed); XCTAssertEqual(result.events.last?.to, .init(row: 7, column: 5))
        XCTAssertEqual(engine.state.portalsUsed.count, 2)
    }
    func testCrystalDurability() {
        let engine = make([shard(), .init(id: "c", kind: .crystal, position: .init(row: 3, column: 2), durability: 2)])
        XCTAssertTrue(engine.apply(.init(entityID: "s")).accepted)
        XCTAssertEqual(engine.state.entities.last?.durability, 1)
        XCTAssertFalse(engine.apply(.init(entityID: "s")).completed)
        XCTAssertTrue(engine.apply(.init(entityID: "s")).completed)
        engine.undo(); XCTAssertEqual(engine.state.moves, 2)
        engine.undo(); XCTAssertEqual(engine.state.entities.last?.durability, 1)
    }
    func testSwitchAndToggle() {
        let engine = make([shard(), shard("b", 4, 3, .up), .init(id: "switch", kind: .controlSwitch, position: .init(row: 3, column: 3), links: ["gate"], oneShot: false), .init(id: "gate", kind: .gate, position: .init(row: 5, column: 5))])
        engine.apply(.init(entityID: "s")); XCTAssertTrue(engine.state.entities.last?.isOpen == true)
        engine.apply(.init(entityID: "b")); XCTAssertFalse(engine.state.entities.last?.isOpen == true)
        engine.undo(); XCTAssertTrue(engine.state.entities.last?.isOpen == true)
    }
    func testReactorDormantChain() {
        let engine = make([shard(), .init(id: "core", kind: .core, position: .init(row: 3, column: 3)), .init(id: "reactor", kind: .reactor, position: .init(row: 1, column: 3), directions: [.right]), .init(id: "sleep", kind: .dormant, position: .init(row: 1, column: 5), direction: .up)])
        let result = engine.apply(.init(entityID: "s"))
        XCTAssertTrue(result.completed); XCTAssertGreaterThanOrEqual(result.chain, 4)
        XCTAssertTrue(engine.state.activated.contains("reactor"))
    }
    func testMagnetAttractionAndRepulsion() {
        for polarity in [PolarityPS.positive, .negative] {
            var s = shard("s", 3, 2, .up); s.polarity = polarity
            let engine = make([s, .init(id: "m", kind: .magnet, position: .init(row: 3, column: 5), polarity: .positive, axis: .horizontal), .init(id: "p", kind: .polaritySwitch, position: .init(row: 6, column: 6), links: ["m"], polarity: .positive)])
            engine.apply(.init(entityID: "p"))
            XCTAssertEqual(engine.state.entities[0].position.column, polarity == .positive ? 3 : 1)
            engine.undo(); XCTAssertEqual(engine.state.entities[0], s)
        }
    }
    func testMagneticDestinationConflict() {
        var a = shard("a", 2, 3); a.polarity = .positive
        var b = shard("b", 3, 2); b.polarity = .positive
        let engine = make([a,b,.init(id: "m", kind: .magnet, position: .init(row: 4, column: 4), polarity: .positive),.init(id: "p", kind: .polaritySwitch, position: .init(row: 6, column: 6), links: ["m"], polarity: .positive)])
        engine.apply(.init(entityID: "p")); XCTAssertEqual(engine.state.entities[0].position, a.position); XCTAssertEqual(engine.state.entities[1].position, b.position)
    }
    func testInvalidPairAndReferences() {
        var level = make([shard(), .init(id: "p", kind: .portal, position: .init(row: 2, column: 2), pair: "missing")]).level
        level.solutionMoves = ["absent"]
        XCTAssertGreaterThanOrEqual(LevelValidatorPS.errors(in: level).count, 2)
    }
    func testScoringAndFailure() {
        XCTAssertEqual(GameResultPS.stars(moves: 3, par: 3), 3)
        XCTAssertEqual(GameResultPS.stars(moves: 5, par: 3), 2)
        XCTAssertEqual(GameResultPS.stars(moves: 6, par: 3), 1)
        let engine = make([shard(), shard("b", 1, 1)], max: 1)
        XCTAssertTrue(engine.apply(.init(entityID: "s")).failed)
    }
    func testDeterminism() {
        let entities = [shard(), .init(id: "c", kind: .crystal, position: .init(row: 3, column: 3), durability: 2)]
        let a = make(entities), b = make(entities)
        for _ in 0..<3 { a.apply(.init(entityID: "s")); b.apply(.init(entityID: "s")); XCTAssertEqual(a.state, b.state) }
    }
}

extension GameEngineTestsPS {
    func testHintAfterAlternateOrderDoesNotPlayMove() {
        let engine = make([shard(), shard("b", 1, 1)])
        engine.apply(.init(entityID: "s"))
        let before = engine.state
        XCTAssertEqual(engine.hint(), "b")
        XCTAssertEqual(engine.state, before)
    }
    func testPortalPreservesDirectionByDefault() {
        let engine = make([shard(), .init(id: "a", kind: .portal, position: .init(row: 3, column: 3), pair: "p"), .init(id: "b", kind: .portal, position: .init(row: 1, column: 5), pair: "p")])
        let result = engine.apply(.init(entityID: "s"))
        XCTAssertEqual(result.events.last?.to, .init(row: 1, column: 7))
    }
    func testClosedGateAndOneShotSwitch() {
        let engine = make([shard(), shard("b", 4, 3, .up), .init(id: "switch", kind: .controlSwitch, position: .init(row: 3, column: 3), links: ["gate"]), .init(id: "gate", kind: .gate, position: .init(row: 5, column: 5))])
        engine.apply(.init(entityID: "s")); engine.apply(.init(entityID: "b"))
        XCTAssertTrue(engine.state.entities.last?.isOpen == true)
        let blocked = make([shard(), .init(id: "gate", kind: .gate, position: .init(row: 3, column: 2))])
        XCTAssertFalse(blocked.apply(.init(entityID: "s")).accepted)
    }
    func testDormantCannotBeTappedAndAdditionalObjectives() {
        let dormant = LevelEntityPS(id: "d", kind: .dormant, position: .init(row: 2, column: 2))
        XCTAssertFalse(make([dormant]).apply(.init(entityID: "d")).accepted)
        var level = make([shard(), .init(id: "c", kind: .crystal, position: .init(row: 0, column: 0))]).level
        level.objectives = [.clearShards, .destroyCrystals]
        let engine = GameEnginePS(level: level)
        XCTAssertFalse(engine.apply(.init(entityID: "s")).completed)
    }
}

extension GameEngineTestsPS {
    func testMinimalEntityDecodingUsesSafeDefaults() throws {
        let data = Data(#"{"id":"s","kind":"shard","position":{"row":1,"column":2}}"#.utf8)
        let entity = try JSONDecoder().decode(LevelEntityPS.self, from: data)
        XCTAssertEqual(entity.direction, .right)
        XCTAssertEqual(entity.turns, 0)
        XCTAssertEqual(entity.links, [])
        XCTAssertEqual(entity.durability, 1)
        XCTAssertEqual(entity, try JSONDecoder().decode(LevelEntityPS.self, from: JSONEncoder().encode(entity)))
    }
}
