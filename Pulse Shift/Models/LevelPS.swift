import Foundation

struct BoardPositionPS: Codable, Hashable {
    var row: Int
    var column: Int
    func step(_ direction: DirectionPS) -> Self {
        .init(row: row + direction.delta.0, column: column + direction.delta.1)
    }
}

enum DirectionPS: String, Codable, CaseIterable {
    case up, right, down, left
    var delta: (Int, Int) {
        switch self { case .up: (-1, 0); case .right: (0, 1); case .down: (1, 0); case .left: (0, -1) }
    }
    var arrow: String {
        switch self { case .up: "↑"; case .right: "→"; case .down: "↓"; case .left: "←" }
    }
    func rotated(_ turns: Int) -> Self {
        let index = Self.allCases.firstIndex(of: self) ?? 0
        return Self.allCases[(index + turns % 4 + 4) % 4]
    }
}

enum EntityKindPS: String, Codable, CaseIterable {
    case shard, wall, redirector, rotator, gate, controlSwitch, portal, crystal, core, reactor, dormant, magnet, polaritySwitch
}

enum PolarityPS: String, Codable {
    case positive, negative
    var flipped: Self { self == .positive ? .negative : .positive }
    var symbol: String { self == .positive ? "+" : "−" }
}

enum MagnetAxisPS: String, Codable { case horizontal, vertical, radial }
enum ObjectivePS: String, Codable { case clearShards, destroyCrystals, activateReactors, usePortals }

struct LevelEntityPS: Codable, Equatable, Identifiable {
    var id: String
    var kind: EntityKindPS
    var position: BoardPositionPS
    var direction: DirectionPS = .right
    var turns: Int = 0
    var links: [String] = []
    var pair: String? = nil
    var isOpen: Bool = false
    var isUsed: Bool = false
    var oneShot: Bool = true
    var durability: Int = 1
    var polarity: PolarityPS? = nil
    var axis: MagnetAxisPS = .radial
    var range: Int = 8
    var directions: [DirectionPS] = [.up, .right, .down, .left]
    var isShard: Bool { kind == .shard || kind == .dormant }
    var isTappable: Bool { kind == .shard || kind == .polaritySwitch }
}

struct LevelPS: Codable, Equatable, Identifiable {
    var id: Int
    var chapter: Int
    var name: String
    var rows: Int
    var columns: Int
    var parMoves: Int
    var maxMoves: Int? = nil
    var objectives: [ObjectivePS] = [.clearShards]
    var entities: [LevelEntityPS]
    var solutionMoves: [String]
    var tutorialMessage: String? = nil
    var contentRevision: Int? = nil
    var designIntent: String? = nil
    func contains(_ position: BoardPositionPS) -> Bool {
        (0..<rows).contains(position.row) && (0..<columns).contains(position.column)
    }
}

struct BoardStatePS: Equatable, Codable {
    var entities: [LevelEntityPS]
    var moves = 0
    var activated: Set<String> = []
    var portalsUsed: Set<String> = []
    var bestChain = 0
}

enum GameEventKindPS: String {
    case move, exit, redirect, gate, activate, portal, crystal, pulse, polarity, magnet, blocked
}

struct GameEventPS {
    var kind: GameEventKindPS
    var entityID: String
    var from: BoardPositionPS
    var to: BoardPositionPS
    var direction: DirectionPS? = nil
    var group: Int = 0
    var remainingDurability: Int? = nil
    var isOpen: Bool? = nil
    var polarity: PolarityPS? = nil
}

struct GameMovePS: Equatable { var entityID: String }
struct MoveResultPS {
    var accepted: Bool
    var events: [GameEventPS]
    var chain: Int
    var completed: Bool
    var failed: Bool
}

struct GameResultPS {
    var moves: Int
    var par: Int
    var chain: Int
    var seconds: Int
    var usedHint: Bool
    var usedUndo: Bool
    var stars: Int { Self.stars(moves: moves, par: par) }
    var perfect: Bool { moves <= par && !usedHint && !usedUndo }
    static func stars(moves: Int, par: Int) -> Int { moves <= par ? 3 : (moves <= par + 2 ? 2 : 1) }
}

extension LevelEntityPS {
    private enum CodingKeysPS: String, CodingKey {
        case id, kind, position, direction, turns, links, pair, isOpen, isUsed, oneShot, durability, polarity, axis, range, directions
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeysPS.self)
        self.init(
            id: try values.decode(String.self, forKey: .id),
            kind: try values.decode(EntityKindPS.self, forKey: .kind),
            position: try values.decode(BoardPositionPS.self, forKey: .position),
            direction: try values.decodeIfPresent(DirectionPS.self, forKey: .direction) ?? .right,
            turns: try values.decodeIfPresent(Int.self, forKey: .turns) ?? 0,
            links: try values.decodeIfPresent([String].self, forKey: .links) ?? [],
            pair: try values.decodeIfPresent(String.self, forKey: .pair),
            isOpen: try values.decodeIfPresent(Bool.self, forKey: .isOpen) ?? false,
            isUsed: try values.decodeIfPresent(Bool.self, forKey: .isUsed) ?? false,
            oneShot: try values.decodeIfPresent(Bool.self, forKey: .oneShot) ?? true,
            durability: try values.decodeIfPresent(Int.self, forKey: .durability) ?? 1,
            polarity: try values.decodeIfPresent(PolarityPS.self, forKey: .polarity),
            axis: try values.decodeIfPresent(MagnetAxisPS.self, forKey: .axis) ?? .radial,
            range: try values.decodeIfPresent(Int.self, forKey: .range) ?? 8,
            directions: try values.decodeIfPresent([DirectionPS].self, forKey: .directions) ?? DirectionPS.allCases
        )
    }
}
