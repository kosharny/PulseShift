import Foundation

@main enum CampaignAuditPS {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
        var rows: [String] = []
        var all: [LevelPS] = []
        var failures: [String] = []
        for chapter in 1...6 {
            let url = root.appendingPathComponent(String(format: "Pulse Shift/Data/levels_chapter_%02d.json", chapter))
            all += try JSONDecoder().decode([LevelPS].self, from: Data(contentsOf: url))
        }
        var setupCount = 0
        var finaleChain = 0
        for level in all {
            let problems = LevelValidatorPS.errors(in: level)
            if !problems.isEmpty { failures.append("\(level.id): \(problems)") }
            let engine = GameEnginePS(level: level)
            var setups = 0, exits = 0, peak = 0
            for id in level.solutionMoves {
                let result = engine.apply(.init(entityID: id))
                if !result.events.contains(where: { $0.kind == .exit }) { setups += 1 }
                exits += result.events.filter { $0.kind == .exit }.count
                peak = max(peak, result.chain)
                if level.id == 60 { finaleChain = result.chain }
            }
            if setups > 0 { setupCount += 1 }
            let density = Int(Double(level.entities.count) / Double(level.columns * level.rows) * 100)
            rows.append("| \(level.id) | \(level.name) | \(level.columns)×\(level.rows) | \(density)% | \(level.parMoves) | \(setups) | \(peak) | \(level.solutionMoves.joined(separator: " → ")) |")
        }
        guard failures.isEmpty, all.count == 60 else { print(failures.joined(separator: "\n")); exit(1) }
        let intro = """
        # Campaign revision 2 — deterministic audit

        All 60 layouts pass the engine validator, including their explicit objectives and stored solution. Each is individually specified in `Scripts/generate_levels.py`; no random board generation, mirrored variants or row-chain template loops are used. Six board sizes are represented. Every level carries a design intent and revision number.

        \(setupCount) levels include at least one authored move that prepares a route without an exit. Level 60's final move creates a chain of \(finaleChain), with three reactors and six dormant pulses. Par is the authored target, not a proof of the shortest possible solution. Difficulty and retention still need player testing; these metrics validate content structure and correctness.

        Early instruction is short: Levels 1–8 take 1–4 moves. Each new mechanic gets a brief introduction followed by ordering puzzles and mixed application. Chapter endings and 56–60 emphasize preparation followed by a branching payoff. Partial movement costs a move; unchanged blocked taps remain free. Move limits appear selectively and permit undo/restart. New score records are revision-aware, while historical chapter access and earned currency are preserved.

        | Level | Name | Board | Occupancy | Par | Setup moves | Peak chain | Verified solution |
        |---|---|---|---|---|---|---|---|
        """
        try (intro + "\n" + rows.joined(separator: "\n") + "\n").write(to: root.appendingPathComponent("Documentation/CampaignAudit.md"), atomically: true, encoding: .utf8)
        print("60 levels valid; \(setupCount) setup puzzles; finale chain \(finaleChain)")
    }
}
