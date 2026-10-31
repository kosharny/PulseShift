import Foundation

struct MoveResolverPS {
    let level: LevelPS
    var state: BoardStatePS
    var events: [GameEventPS] = []
    var chain = 0
    var overflow = false
    private var queue: [String] = []
    private var emitted: Set<String> = []
    private var switchHits: Set<String> = []
    private var steps = 0

    init(level: LevelPS, state: BoardStatePS) { self.level = level; self.state = state }

    mutating func resolve(_ id: String) {
        if entity(id)?.kind == .polaritySwitch { changePolarity(id) } else { queue.append(id) }
        var cursor = 0
        while cursor < queue.count, steps < 2048 {
            let next = queue[cursor]
            cursor += 1
            travel(next)
        }
        overflow = steps >= 2048
    }

    private func entity(_ id: String) -> LevelEntityPS? { state.entities.first { $0.id == id } }
    private mutating func update(_ entity: LevelEntityPS) {
        if let index = state.entities.firstIndex(where: { $0.id == entity.id }) { state.entities[index] = entity }
    }
    private mutating func event(_ kind: GameEventKindPS, _ id: String, _ from: BoardPositionPS, _ to: BoardPositionPS? = nil, direction: DirectionPS? = nil, group: Int? = nil, durability: Int? = nil, isOpen: Bool? = nil, polarity: PolarityPS? = nil) {
        events.append(.init(kind: kind, entityID: id, from: from, to: to ?? from, direction: direction, group: group ?? (events.last.map { $0.group + 1 } ?? 0), remainingDurability: durability, isOpen: isOpen, polarity: polarity))
    }
    private func occupant(_ position: BoardPositionPS, excluding id: String) -> LevelEntityPS? {
        state.entities.filter { $0.position == position && $0.id != id }.sorted {
            if $0.isShard != $1.isShard { return $0.isShard }
            return $0.id < $1.id
        }.first
    }

    private mutating func travel(_ id: String) {
        guard var shard = entity(id), shard.kind == .shard else { return }
        var visited = Set<String>()
        while steps < 2048 {
            steps += 1
            let key = "\(shard.position.row),\(shard.position.column),\(shard.direction.rawValue),\(state.entities)"
            guard visited.insert(key).inserted else { return }
            let next = shard.position.step(shard.direction)
            guard level.contains(next) else {
                event(.exit, id, shard.position, next)
                state.entities.removeAll { $0.id == id }
                chain += 1
                return
            }
            let target = occupant(next, excluding: id)
            if let target {
                if target.kind == .wall || target.isShard || (target.kind == .gate && !target.isOpen) || target.kind == .magnet || target.kind == .polaritySwitch { return }
                if target.kind == .crystal { damage(target); return }
            }
            event(.move, id, shard.position, next)
            shard.position = next
            update(shard)
            guard let target else { continue }
            switch target.kind {
            case .redirector, .rotator:
                shard.direction = shard.direction.rotated(target.turns)
                update(shard)
                event(.redirect, id, next, direction: shard.direction)
            case .controlSwitch: activateSwitch(target)
            case .portal:
                guard let partner = state.entities.first(where: { $0.kind == .portal && $0.pair == target.pair && $0.id != target.id }), !state.entities.contains(where: { $0.isShard && $0.id != id && $0.position == partner.position }) else { return }
                state.portalsUsed.formUnion([target.id, partner.id])
                shard.position = partner.position
                shard.direction = shard.direction.rotated(target.turns)
                update(shard)
                event(.portal, id, next, partner.position, direction: shard.direction)
            case .core, .reactor: emit(target)
            default: break
            }
        }
    }

    private mutating func damage(_ crystal: LevelEntityPS) {
        var crystal = crystal
        crystal.durability -= 1
        event(.crystal, crystal.id, crystal.position, durability: crystal.durability)
        if crystal.durability <= 0 {
            state.entities.removeAll { $0.id == crystal.id }
            chain += 1
        } else { update(crystal) }
    }

    private mutating func activateSwitch(_ control: LevelEntityPS) {
        guard !switchHits.contains(control.id), !(control.oneShot && control.isUsed) else { return }
        switchHits.insert(control.id)
        var control = control
        control.isUsed = true
        update(control)
        event(.activate, control.id, control.position)
        chain += 1
        let group = (events.last?.group ?? 0) + 1
        for id in control.links.sorted() {
            guard var linked = entity(id) else { continue }
            if linked.kind == .gate {
                linked.isOpen.toggle()
                update(linked)
                event(.gate, id, linked.position, group: group, isOpen: linked.isOpen)
            } else if linked.kind == .dormant {
                linked.kind = .shard
                update(linked)
                event(.activate, id, linked.position, group: group)
                queue.append(id)
            }
        }
    }

    private mutating func emit(_ source: LevelEntityPS) {
        guard emitted.insert(source.id).inserted, steps < 2048 else { return }
        steps += 1
        state.activated.insert(source.id)
        event(.activate, source.id, source.position)
        chain += 1
        let pulseGroup = (events.last?.group ?? 0) + 1
        var hits: [LevelEntityPS] = []
        for direction in source.kind == .core ? DirectionPS.allCases : source.directions {
            var position = source.position.step(direction)
            var end = source.position
            while level.contains(position) {
                end = position
                if let target = occupant(position, excluding: source.id) {
                    if target.kind == .gate && target.isOpen { position = position.step(direction); continue }
                    hits.append(target)
                    break
                }
                position = position.step(direction)
            }
            event(.pulse, source.id, source.position, end, group: pulseGroup)
        }
        for target in hits {
            switch target.kind {
            case .core, .reactor: emit(target)
            case .controlSwitch: activateSwitch(target)
            case .crystal: if let current = entity(target.id) { damage(current) }
            case .dormant:
                if var current = entity(target.id), current.kind == .dormant {
                    current.kind = .shard
                    update(current)
                    event(.activate, current.id, current.position)
                    queue.append(current.id)
                }
            default: break
            }
        }
    }

    private mutating func changePolarity(_ id: String) {
        guard var control = entity(id) else { return }
        control.polarity = (control.polarity ?? .positive).flipped
        update(control)
        event(.polarity, id, control.position, polarity: control.polarity)
        var magnets: [LevelEntityPS] = []
        for target in state.entities where target.kind == .magnet && (control.links.isEmpty || control.links.contains(target.id)) {
            var magnet = target
            magnet.polarity = control.polarity
            update(magnet)
            magnets.append(magnet)
            event(.polarity, magnet.id, magnet.position, polarity: magnet.polarity)
        }
        let original = state.entities
        var proposals: [String: BoardPositionPS] = [:]
        for shard in original where shard.isShard && shard.polarity != nil {
            var destinations = Set<BoardPositionPS>()
            for magnet in magnets.sorted(by: { $0.id < $1.id }) {
                let dr = magnet.position.row - shard.position.row
                let dc = magnet.position.column - shard.position.column
                guard abs(dr) + abs(dc) <= magnet.range,
                      magnet.axis != .horizontal || dr == 0,
                      magnet.axis != .vertical || dc == 0 else { continue }
                let attraction = magnet.polarity != shard.polarity
                let sign = attraction ? 1 : -1
                let destination: BoardPositionPS
                if abs(dc) >= abs(dr), dc != 0 {
                    destination = .init(row: shard.position.row, column: shard.position.column + (dc > 0 ? sign : -sign))
                } else if dr != 0 {
                    destination = .init(row: shard.position.row + (dr > 0 ? sign : -sign), column: shard.position.column)
                } else { continue }
                destinations.insert(destination)
            }
            if destinations.count == 1, let destination = destinations.first, level.contains(destination), !original.contains(where: { $0.position == destination }) {
                proposals[shard.id] = destination
            }
        }
        let counts = Dictionary(grouping: proposals.values, by: { $0 }).mapValues(\.count)
        let group = (events.last?.group ?? 0) + 1
        for id in proposals.keys.sorted() {
            guard let destination = proposals[id], counts[destination] == 1, var shard = entity(id) else { continue }
            event(.magnet, id, shard.position, destination, group: group)
            shard.position = destination
            update(shard)
        }
    }
}
