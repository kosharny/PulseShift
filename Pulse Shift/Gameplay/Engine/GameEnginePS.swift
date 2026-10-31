import Foundation

final class GameEnginePS {
    let level: LevelPS
    private(set) var state: BoardStatePS
    private var history: [BoardStatePS] = []
    private(set) var playedMoves: [String] = []
    var canUndo: Bool { !history.isEmpty }
    var completed: Bool {
        level.objectives.allSatisfy { objective in
            switch objective {
            case .clearShards: !state.entities.contains(where: \.isShard)
            case .destroyCrystals: !state.entities.contains { $0.kind == .crystal }
            case .activateReactors: level.entities.filter { $0.kind == .reactor }.allSatisfy { state.activated.contains($0.id) }
            case .usePortals: level.entities.filter { $0.kind == .portal }.allSatisfy { state.portalsUsed.contains($0.id) }
            }
        }
    }
    var stranded: Bool { !completed && !state.entities.contains { $0.kind == .shard } }
    var failed: Bool { !completed && (stranded || level.maxMoves.map { state.moves >= $0 } == true) }

    init(level: LevelPS, state: BoardStatePS? = nil) {
        self.level = level
        self.state = state ?? BoardStatePS(entities: level.entities)
    }

    @discardableResult func apply(_ move: GameMovePS) -> MoveResultPS {
        guard !completed, !failed, let entity = state.entities.first(where: { $0.id == move.entityID }), entity.isTappable else {
            return .init(accepted: false, events: [], chain: 0, completed: completed, failed: failed)
        }
        let before = state
        var resolver = MoveResolverPS(level: level, state: state)
        resolver.resolve(entity.id)
        guard resolver.state != before, !resolver.overflow else {
            return .init(accepted: false, events: [.init(kind: .blocked, entityID: entity.id, from: entity.position, to: entity.position)], chain: 0, completed: false, failed: false)
        }
        history.append(before)
        playedMoves.append(entity.id)
        state = resolver.state
        state.moves += 1
        state.bestChain = max(state.bestChain, resolver.chain)
        return .init(accepted: true, events: resolver.events, chain: resolver.chain, completed: completed, failed: failed)
    }

    var hasAvailableMove: Bool {
        state.entities.filter(\.isTappable).contains { entity in
            var resolver = MoveResolverPS(level: level, state: state)
            resolver.resolve(entity.id)
            return !resolver.overflow && resolver.state != state
        }
    }
    func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
        if !playedMoves.isEmpty { playedMoves.removeLast() }
    }

    func restart() {
        state = BoardStatePS(entities: level.entities)
        history.removeAll()
        playedMoves.removeAll()
    }

    func hint() -> String? {
        let solution = level.solutionMoves
        if Array(solution.prefix(playedMoves.count)) == playedMoves, playedMoves.count < solution.count {
            return solution[playedMoves.count]
        }
        // Match a canonical solution snapshot after an alternate but equivalent ordering.
        let canonical = GameEnginePS(level: level)
        for id in solution {
            if canonical.state.entities == state.entities && canonical.state.activated == state.activated {
                return id
            }
            canonical.apply(.init(entityID: id))
        }
        var visited = Set<String>()
        var budget = 1800
        func search(_ board: BoardStatePS, depth: Int) -> String? {
            guard depth > 0, budget > 0 else { return nil }
            budget -= 1
            let key = String(describing: board.entities) + "\(board.moves)\(board.activated.sorted())\(board.portalsUsed.sorted())"
            guard visited.insert(key).inserted else { return nil }
            for entity in board.entities.filter(\.isTappable).sorted(by: { $0.id < $1.id }) {
                let engine = GameEnginePS(level: level, state: board)
                let result = engine.apply(.init(entityID: entity.id))
                guard result.accepted else { continue }
                if result.completed || search(engine.state, depth: depth - 1) != nil { return entity.id }
            }
            return nil
        }
        return search(state, depth: min(12, solution.count + 2))
    }
}
