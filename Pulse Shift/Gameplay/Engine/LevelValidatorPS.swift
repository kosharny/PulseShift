import Foundation

struct LevelValidatorPS {
    static func errors(in level: LevelPS, replaySolution: Bool = true) -> [String] {
        var errors: [String] = []
        if level.rows < 2 || level.columns < 2 || level.parMoves < 1 { errors.append("Invalid board dimensions or par") }
        let ids = level.entities.map(\.id)
        if Set(ids).count != ids.count { errors.append("Duplicate entity IDs") }
        if Set(level.entities.map(\.position)).count != level.entities.count { errors.append("Overlapping entities") }
        for entity in level.entities {
            if !level.contains(entity.position) { errors.append("Out of bounds: \(entity.id)") }
            if entity.kind == .portal, entity.pair == nil || level.entities.filter({ $0.kind == .portal && $0.pair == entity.pair }).count != 2 { errors.append("Invalid portal pair: \(entity.id)") }
            if entity.kind == .crystal && !(1...2).contains(entity.durability) { errors.append("Invalid crystal durability") }
            for link in entity.links where !ids.contains(link) { errors.append("Missing link: \(link)") }
            if entity.kind == .gate && !entity.isOpen && !level.entities.contains(where: { $0.kind == .controlSwitch && $0.links.contains(entity.id) }) { errors.append("Gate without switch: \(entity.id)") }
        }
        if level.solutionMoves.isEmpty || !level.solutionMoves.allSatisfy({ ids.contains($0) }) { errors.append("Invalid solution references") }
        guard errors.isEmpty, replaySolution else { return errors }
        let engine = GameEnginePS(level: level)
        for id in level.solutionMoves {
            if !engine.apply(.init(entityID: id)).accepted { errors.append("Solution blocked at \(id), move \(engine.state.moves + 1)"); break }
        }
        if !engine.completed { errors.append("Stored solution does not complete level") }
        if engine.state.moves > level.parMoves { errors.append("Stored solution exceeds par") }
        return errors
    }
}

struct LevelCatalogPS {
    var levels: [LevelPS] = []
    var errors: [String] = []
    init(bundle: Bundle = .main) {
        for chapter in 1...6 {
            let name = String(format: "levels_chapter_%02d", chapter)
            guard let url = bundle.url(forResource: name, withExtension: "json") else { errors.append("Missing \(name)"); continue }
            do {
                guard let records = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [Any] else {
                    errors.append("\(name): Expected an array of levels"); continue
                }
                for record in records {
                    guard JSONSerialization.isValidJSONObject(record) else { errors.append("\(name): Invalid level record"); continue }
                    do {
                        let level = try JSONDecoder().decode(LevelPS.self, from: JSONSerialization.data(withJSONObject: record))
                        let problems = LevelValidatorPS.errors(in: level)
                        if problems.isEmpty { levels.append(level) } else { errors.append("Level \(level.id): \(problems.joined(separator: ", "))") }
                    } catch { errors.append("\(name): \(error.localizedDescription)") }
                }
            } catch { errors.append("\(name): \(error.localizedDescription)") }
        }
        levels.sort { $0.id < $1.id }
        #if DEBUG
        for error in errors { print("PULSE SHIFT level validation: \(error)") }
        #endif
    }
}
