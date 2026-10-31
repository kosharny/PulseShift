import SpriteKit
import SwiftUI

struct BoardLayoutPS {
    var rows: Int
    var columns: Int
    var size: CGSize
    var cell: CGFloat { min(size.width / CGFloat(columns), size.height / CGFloat(rows)) }
    func point(_ position: BoardPositionPS) -> CGPoint {
        CGPoint(x: (size.width - CGFloat(columns) * cell) / 2 + (CGFloat(position.column) + 0.5) * cell,
                y: (size.height + CGFloat(rows) * cell) / 2 - (CGFloat(position.row) + 0.5) * cell)
    }
    func position(_ point: CGPoint) -> BoardPositionPS {
        .init(row: Int(floor(((size.height + CGFloat(rows) * cell) / 2 - point.y) / cell)),
              column: Int(floor((point.x - (size.width - CGFloat(columns) * cell) / 2) / cell)))
    }
}

@MainActor final class GameScenePS: SKScene {
    var onTap: ((String) -> Void)?
    var onEvent: ((GameEventPS, Int) -> Void)?
    var reducedEffects = false
    var debugLabels = false
    private var boardLevel: LevelPS?
    private var boardState: BoardStatePS?
    private var theme = ThemePS.all[0]
    private let gridLayer = SKNode()
    private let entityLayer = SKNode()
    private let effectsLayer = SKNode()
    private var nodesByID: [String: SKNode] = [:]
    private var busy = false
    private var presentedChain = 0
    private var pressedID: String?
    private var layout: BoardLayoutPS { .init(rows: boardLevel?.rows ?? 9, columns: boardLevel?.columns ?? 7, size: size) }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = .clear
        addChild(gridLayer); addChild(entityLayer); addChild(effectsLayer)
        entityLayer.zPosition = 2
        effectsLayer.zPosition = 10
    }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

    func configure(level: LevelPS, state: BoardStatePS, theme: ThemePS, animated: Bool = false) {
        removeAllActions(); effectsLayer.removeAllChildren(); entityLayer.removeAllActions()
        isPaused = false; busy = false; entityLayer.position = .zero; pressedID = nil
        boardLevel = level; boardState = state; self.theme = theme
        size = CGSize(width: CGFloat(level.columns) * 100, height: CGFloat(level.rows) * 100)
        gridLayer.removeAllChildren()
        let base = SKShapeNode(rectOf: size, cornerRadius: 32)
        base.position = CGPoint(x: size.width / 2, y: size.height / 2)
        base.fillColor = UIColor(theme.surface); base.strokeColor = UIColor(ColorPS.blue).withAlphaComponent(0.65); base.lineWidth = 8
        let innerFrame = SKShapeNode(rectOf: CGSize(width: size.width - 16, height: size.height - 16), cornerRadius: 26)
        innerFrame.position = base.position; innerFrame.strokeColor = UIColor(theme.accent).withAlphaComponent(0.25); innerFrame.lineWidth = 2
        gridLayer.addChild(innerFrame)
        for x in [CGFloat(13), size.width - 13] {
            for y in [CGFloat(15), size.height - 15] {
                let corner = SKShapeNode(rectOf: CGSize(width: 30, height: 5), cornerRadius: 2)
                corner.position = CGPoint(x: x < size.width / 2 ? x + 19 : x - 19, y: y)
                corner.fillColor = UIColor(theme.accent); corner.strokeColor = .clear; corner.glowWidth = reducedEffects ? 0 : 6
                corner.zPosition = 1; gridLayer.addChild(corner)
            }
        }
        gridLayer.addChild(base)
        if let texture = SpriteArtPS.named("gameplay_board_frame") {
            let frame = SKSpriteNode(texture: texture); frame.size = size; frame.position = base.position; frame.zPosition = 0.5
            gridLayer.addChild(frame)
        }
        for row in 0..<level.rows {
            for column in 0..<level.columns {
                let point = layout.point(.init(row: row, column: column))
                let cell = SKShapeNode(rectOf: CGSize(width: 88, height: 88), cornerRadius: 18)
                cell.position = point; cell.fillColor = UIColor(ColorPS.elevated).withAlphaComponent((row + column) % 2 == 0 ? 0.34 : 0.25)
                cell.strokeColor = UIColor(ColorPS.grid).withAlphaComponent(0.85); cell.lineWidth = 1.5
                gridLayer.addChild(cell)
                if let texture = SpriteArtPS.named("gameplay_cell") {
                    let art = SKSpriteNode(texture: texture); art.size = CGSize(width: 88, height: 88); art.position = point; art.zPosition = 0.6
                    gridLayer.addChild(art)
                }
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.position = CGPoint(x: point.x - 48, y: point.y + 48)
                dot.fillColor = UIColor(ColorPS.secondary).withAlphaComponent(0.2); dot.strokeColor = .clear
                gridLayer.addChild(dot)
            }
        }
        render(state)
        if animated && !reducedEffects {
            for (index, node) in entityLayer.children.enumerated() {
                let originalAlpha = node.alpha; node.alpha = 0; node.setScale(0.65)
                node.run(.sequence([.wait(forDuration: Double(index % 7) * 0.018), .group([.fadeAlpha(to: originalAlpha, duration: 0.15), .sequence([.scale(to: 1.08, duration: 0.16), .scale(to: 1, duration: 0.09)])])]))
            }
        }
    }

    private func render(_ state: BoardStatePS) {
        entityLayer.removeAllChildren(); nodesByID.removeAll()
        boardState = state
        for entity in state.entities {
            let node = EntityNodeFactoryPS.make(entity, theme: theme, reduced: reducedEffects)
            node.position = layout.point(entity.position); node.name = entity.id
            entityLayer.addChild(node); nodesByID[entity.id] = node
            if debugLabels {
                let label = SKLabelNode(fontNamed: "Menlo")
                label.text = "\(entity.id) \(entity.position.row),\(entity.position.column) \(entity.direction.arrow) \(entity.pair ?? entity.links.joined(separator: ","))"
                label.fontSize = 12; label.fontColor = .white; label.position.y = -43; node.addChild(label)
            }
        }
    }

    func clearHighlight() {
        effectsLayer.childNode(withName: "hint")?.removeFromParent()
    }

    func highlight(_ id: String) {
        clearHighlight()
        guard let node = nodesByID[id] else { return }
        let ring = SKShapeNode(rectOf: CGSize(width: 88, height: 88), cornerRadius: 23)
        ring.name = "hint"; ring.position = node.position; ring.strokeColor = UIColor(ColorPS.warning)
        ring.lineWidth = 4; ring.glowWidth = reducedEffects ? 0 : 4
        effectsLayer.addChild(ring)
        if !reducedEffects { ring.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35, duration: 0.5), .fadeAlpha(to: 1, duration: 0.5)]))) }
    }

    func animate(_ result: MoveResultPS, finalState: BoardStatePS, completion: @escaping () -> Void) {
        busy = true; presentedChain = 0; effectsLayer.childNode(withName: "hint")?.removeFromParent()
        let groups = MoveAnimationPS(events: result.events).groups
        var actions: [SKAction] = []
        if let first = result.events.first, first.kind != .blocked {
            actions += [.run { [weak self] in self?.press(first.entityID); self?.trajectory(first.entityID) }, .wait(forDuration: reducedEffects ? 0 : 0.16)]
        }
        for (index, group) in groups.enumerated() {
            let baseDuration = group.map { event in
                let distance = abs(event.to.row - event.from.row) + abs(event.to.column - event.from.column)
                return self.duration(event.kind) * Double(event.kind == .move ? max(1, distance) : 1)
            }.max() ?? 0.1
            let isFinalChain = result.completed && result.chain >= 5 && index >= groups.count - 2
            let duration = isFinalChain && !reducedEffects ? max(0.15, baseDuration) : baseDuration
            actions += [.run { [weak self] in
                guard let self else { return }
                for event in group {
                    let originalKind = self.boardLevel?.entities.first { $0.id == event.entityID }?.kind
                    let addsChain = event.kind == .exit || (event.kind == .crystal && event.remainingDurability == 0) || (event.kind == .activate && originalKind.map { [.core, .reactor, .controlSwitch].contains($0) } == true)
                    if addsChain { self.presentedChain += 1 }
                    self.present(event, duration: duration)
                    if event.kind != .move && event.kind != .pulse { self.onEvent?(event, min(self.presentedChain, result.chain)) }
                    if addsChain && self.presentedChain >= 3 { self.comboPopup(self.presentedChain, at: self.layout.point(event.to)) }
                }
            }, .wait(forDuration: duration)]
        }
        actions.append(.run { [weak self] in
            guard let self else { return }
            self.render(finalState)
            if result.completed { self.completionPulse(chain: result.chain) }
        })
        if result.completed { actions.append(.wait(forDuration: reducedEffects ? 0.15 : 0.45)) }
        actions.append(.run { [weak self] in self?.busy = false; completion() })
        run(.sequence(actions), withKey: "resolution")
    }

    func settle(state: BoardStatePS) {
        removeAllActions(); effectsLayer.removeAllChildren(); entityLayer.removeAllActions(); entityLayer.position = .zero
        render(state); busy = false
    }

    private func duration(_ kind: GameEventKindPS) -> Double {
        if reducedEffects { return kind == .move ? 0.06 : 0.1 }
        switch kind {
        case .move, .exit: return presentedChain >= 5 ? 0.065 : 0.085
        case .portal: return 0.25
        case .gate, .crystal, .activate, .polarity, .magnet: return 0.2
        default: return 0.12
        }
    }

    private func trajectory(_ id: String) {
        guard let entity = boardState?.entities.first(where: { $0.id == id }), entity.isShard else { return }
        var end = entity.position
        for _ in 0..<10 {
            let next = end.step(entity.direction)
            guard boardLevel?.contains(next) == true else { break }
            if boardState?.entities.contains(where: { $0.position == next && $0.id != id }) == true { break }
            end = next
        }
        beam(from: layout.point(entity.position), to: layout.point(end), color: UIColor(theme.accent), duration: 0.2, width: 3)
    }

    private func present(_ event: GameEventPS, duration: Double) {
        let from = layout.point(event.from), to = layout.point(event.to)
        let node = nodesByID[event.entityID]
        switch event.kind {
        case .move, .exit, .magnet:
            let move = SKAction.move(to: to, duration: duration)
            move.timingMode = event.kind == .magnet ? .easeInEaseOut : .linear
            node?.run(move, withKey: "travel")
            if !reducedEffects { beam(from: from, to: to, color: UIColor(theme.accent), duration: duration + 0.2, width: 10) }
            if event.kind == .exit {
                burst(at: from, color: UIColor(theme.accent), count: 10)
                node?.run(.sequence([.group([.scale(to: reducedEffects ? 1 : 1.22, duration: duration), .fadeOut(withDuration: duration)]), .removeFromParent()]))
            } else if event.kind == .magnet && !reducedEffects {
                node?.run(.sequence([.scale(to: 0.87, duration: 0.07), .scale(to: 1.08, duration: 0.09), .scale(to: 1, duration: 0.06)]))
            }
        case .portal:
            if let direction = event.direction { node?.childNode(withName: "direction")?.zRotation = EntityNodeFactoryPS.rotation(direction) }
            pulse(at: from, color: UIColor(ColorPS.violet))
            if reducedEffects { node?.position = to }
            else { node?.run(.sequence([.scale(to: 0.1, duration: duration / 2), .move(to: to, duration: 0), .scale(to: 1, duration: duration / 2)])) }
            pulse(at: to, color: UIColor(theme.accent))
        case .redirect:
            (node?.childNode(withName: "glyph") as? SKLabelNode)?.text = ""
            if let direction = event.direction { node?.childNode(withName: "direction")?.zRotation = EntityNodeFactoryPS.rotation(direction) }
            pulse(at: from, color: UIColor(ColorPS.violet))
        case .pulse: beam(from: from, to: to, color: UIColor(theme.accent), duration: duration, width: 9)
        case .blocked:
            if !reducedEffects { node?.run(.sequence([.moveBy(x: -7, y: 0, duration: 0.04), .moveBy(x: 14, y: 0, duration: 0.04), .moveBy(x: -7, y: 0, duration: 0.04)])) }
            pulse(at: from, color: UIColor(ColorPS.danger))
        case .gate:
            let open = event.isOpen ?? true
            node?.run(.fadeAlpha(to: open ? 0.3 : 1, duration: duration))
            node?.children.filter { $0.name == "segment" }.enumerated().forEach { index, segment in
                segment.run(.moveTo(x: CGFloat(index == 0 ? -19 : 19) * (open ? 1.6 : 1), duration: duration))
            }
            pulse(at: from, color: UIColor(ColorPS.green))
        case .crystal:
            let destroyed = event.remainingDurability == 0
            burst(at: from, color: UIColor(ColorPS.warning), count: destroyed ? 16 : 5, asset: "fx_crystal_shard")
            if destroyed { node?.run(.group([.scale(to: reducedEffects ? 1 : 1.25, duration: duration), .fadeOut(withDuration: duration)])); shake(amount: 3) }
            else { (node?.childNode(withName: "glyph") as? SKLabelNode)?.text = "╱"; pulse(at: from, color: UIColor(ColorPS.warning)) }
        case .activate:
            node?.alpha = 1
            burst(at: from, color: UIColor(theme.accent), count: 7)
            pulse(at: from, color: UIColor(theme.accent))
            if !reducedEffects { node?.run(.sequence([.scale(to: 1.15, duration: duration / 2), .scale(to: 1, duration: duration / 2)])) }
        case .polarity:
            let label = node?.childNode(withName: "glyph") as? SKLabelNode
            label?.text = event.polarity?.symbol ?? "+"
            pulse(at: from, color: UIColor(ColorPS.pink))
        }
    }

    private func beam(from: CGPoint, to: CGPoint, color: UIColor, duration: Double, width: CGFloat) {
        let beam: SKNode
        if let texture = SpriteArtPS.named("fx_trail") {
            let art = SKSpriteNode(texture: texture)
            art.size = CGSize(width: hypot(to.x - from.x, to.y - from.y), height: width * 3)
            art.anchorPoint = CGPoint(x: 0, y: 0.5); art.position = from
            art.zRotation = atan2(to.y - from.y, to.x - from.x); art.color = color; art.colorBlendFactor = 1
            beam = art
        } else {
            let path = CGMutablePath(); path.move(to: from); path.addLine(to: to)
            let shape = SKShapeNode(path: path); shape.strokeColor = color; shape.lineWidth = width
            shape.glowWidth = reducedEffects ? 0 : 7; beam = shape
        }
        beam.alpha = 0.85
        effectsLayer.addChild(beam); beam.run(.sequence([.fadeOut(withDuration: duration), .removeFromParent()]))
    }
    private func pulse(at point: CGPoint, color: UIColor) {
        let ring: SKNode
        if let texture = SpriteArtPS.named("fx_glow_ring") {
            let art = SKSpriteNode(texture: texture); art.size = CGSize(width: 64, height: 64); art.color = color; art.colorBlendFactor = 1; ring = art
        } else {
            let shape = SKShapeNode(circleOfRadius: 32); shape.strokeColor = color; shape.lineWidth = 4; shape.glowWidth = reducedEffects ? 0 : 4; ring = shape
        }
        ring.position = point; effectsLayer.addChild(ring)
        ring.run(.sequence([.group([.scale(to: reducedEffects ? 1 : 2.6, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
    }
    private func burst(at point: CGPoint, color: UIColor, count: Int, asset: String = "fx_spark") {
        guard !reducedEffects else { pulse(at: point, color: color); return }
        for index in 0..<min(count, max(0, 80 - effectsLayer.children.count)) {
            let angle = CGFloat(index) / CGFloat(count) * .pi * 2
            let spark: SKNode
            if let texture = SpriteArtPS.named(asset) {
                let art = SKSpriteNode(texture: texture); art.size = CGSize(width: 12, height: 16); art.color = color; art.colorBlendFactor = 1; spark = art
            } else {
                let shape = SKShapeNode(rectOf: CGSize(width: 4, height: 12), cornerRadius: 2); shape.fillColor = color; shape.strokeColor = .clear; spark = shape
            }
            spark.position = point; spark.zRotation = angle; effectsLayer.addChild(spark)
            spark.run(.sequence([.group([.moveBy(x: cos(angle) * 65, y: sin(angle) * 65, duration: 0.32), .fadeOut(withDuration: 0.32)]), .removeFromParent()]))
        }
    }
    private func completionPulse(chain: Int) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        pulse(at: center, color: UIColor(theme.accent))
        guard !reducedEffects else { return }
        let wave = SKShapeNode(circleOfRadius: 50); wave.position = center; wave.strokeColor = UIColor(ColorPS.warning); wave.lineWidth = 8
        effectsLayer.addChild(wave)
        wave.run(.sequence([.group([.scale(to: size.height / 70, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
        guard !reducedEffects else { return }
        for index in 0..<20 {
            let angle = CGFloat(index) * .pi / 10
            let spark = SKShapeNode(circleOfRadius: 3)
            spark.fillColor = UIColor(theme.accent); spark.strokeColor = .clear; spark.glowWidth = 4
            spark.position = CGPoint(x: center.x + cos(angle) * size.width / 2, y: center.y + sin(angle) * size.width / 2)
            effectsLayer.addChild(spark)
            spark.run(.sequence([.group([.move(to: center, duration: 0.4), .fadeOut(withDuration: 0.4)]), .removeFromParent()]))
        }
        if chain >= 5 { entityLayer.run(.sequence([.moveBy(x: 3, y: 0, duration: 0.04), .moveBy(x: -6, y: 0, duration: 0.04), .moveBy(x: 3, y: 0, duration: 0.04)])) }
    }

    private func press(_ id: String) {
        guard !reducedEffects, let node = nodesByID[id] else { return }
        node.removeAction(forKey: "press")
        node.run(.sequence([.scale(to: 0.94, duration: 0.05), .scale(to: 1, duration: 0.1)]), withKey: "press")
    }
    private func shake(amount: CGFloat) {
        guard !reducedEffects, entityLayer.action(forKey: "shake") == nil else { return }
        entityLayer.run(.sequence([.moveBy(x: amount, y: 1, duration: 0.035), .moveBy(x: -amount * 2, y: -2, duration: 0.05), .moveBy(x: amount, y: 1, duration: 0.035)]), withKey: "shake")
    }
    private func comboPopup(_ count: Int, at point: CGPoint) {
        guard count == 3 || count == 5 || count == 8 || count % 5 == 0 else { return }
        effectsLayer.childNode(withName: "combo")?.removeFromParent()
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.name = "combo"; label.text = count >= 8 ? "SUPER CHAIN ×\(count)!" : "CHAIN ×\(count)!"
        label.fontSize = 30; label.fontColor = UIColor(count >= 5 ? ColorPS.warning : ColorPS.cyan)
        label.position = CGPoint(x: size.width / 2, y: size.height - 46); label.zPosition = 30
        effectsLayer.addChild(label)
        label.setScale(reducedEffects ? 1 : 0.7)
        if reducedEffects { label.run(.sequence([.wait(forDuration: 0.4), .fadeOut(withDuration: 0.2), .removeFromParent()])) }
        else { label.run(.sequence([.scale(to: 1.12, duration: 0.1), .scale(to: 1, duration: 0.08), .wait(forDuration: 0.4), .fadeOut(withDuration: 0.2), .removeFromParent()])) }
        if count >= 5 { shake(amount: 4); pulse(at: CGPoint(x: size.width / 2, y: size.height / 2), color: UIColor(theme.accent)) }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !busy, let touch = touches.first else { return }
        let position = layout.position(touch.location(in: self))
        if let entity = boardState?.entities.first(where: { $0.position == position && $0.isTappable }) { pressedID = entity.id; press(entity.id) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let id = pressedID { nodesByID[id]?.removeAction(forKey: "press"); nodesByID[id]?.setScale(1) }
        pressedID = nil
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !busy, let touch = touches.first, let state = boardState else { return }
        let cell = layout.position(touch.location(in: self))
        let releasedID = pressedID
        pressedID = nil
        if let entity = state.entities.first(where: { $0.position == cell && $0.isTappable }), entity.id == releasedID {
            onTap?(entity.id)
        }
    }
}
