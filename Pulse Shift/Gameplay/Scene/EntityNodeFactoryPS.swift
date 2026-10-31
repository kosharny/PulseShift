import SpriteKit
import SwiftUI

@MainActor enum EntityNodeFactoryPS {
    static func rotation(_ direction: DirectionPS) -> CGFloat {
        switch direction { case .up: 0; case .right: -.pi / 2; case .down: .pi; case .left: .pi / 2 }
    }
    static func make(_ entity: LevelEntityPS, theme: ThemePS, reduced: Bool) -> SKNode {
        let container = SKNode()
        let accent = SpriteArtPS.color(for: entity, theme: theme)
        let shape: SKShapeNode
        var glyph = ""
        var fill = UIColor(theme.surface)
        var stroke = accent
        switch entity.kind {
        case .shard, .dormant:
            shape = SKShapeNode(rectOf: CGSize(width: 80, height: 80), cornerRadius: 22)
            glyph = ""; fill = accent.withAlphaComponent(0.45)
            if entity.kind == .dormant { container.alpha = 0.38 }
        case .wall:
            shape = SKShapeNode(rectOf: CGSize(width: 76, height: 76), cornerRadius: 10)
            fill = UIColor(ColorPS.elevated); stroke = UIColor(ColorPS.muted).withAlphaComponent(0.5)
            glyph = ""
        case .redirector:
            shape = SKShapeNode(rectOf: CGSize(width: 59, height: 59), cornerRadius: 14)
            stroke = UIColor(ColorPS.violet); glyph = entity.turns == 2 || entity.turns == -2 ? "↶" : (entity.turns > 0 ? "↱" : "↰")
        case .rotator:
            shape = SKShapeNode(circleOfRadius: 31); stroke = UIColor(ColorPS.violet)
            glyph = entity.turns > 0 ? "↻" : "↺"
        case .gate:
            shape = SKShapeNode(rectOf: CGSize(width: 78, height: 78), cornerRadius: 10)
            stroke = UIColor(ColorPS.green).withAlphaComponent(0.45)
            for x in [-19.0, 19.0] {
                let segment = SKShapeNode(rectOf: CGSize(width: 21, height: 59), cornerRadius: 5)
                segment.name = "segment"; segment.fillColor = UIColor(ColorPS.green).withAlphaComponent(0.5)
                segment.strokeColor = UIColor(ColorPS.green); segment.position.x = entity.isOpen ? x * 1.6 : x
                container.addChild(segment)
            }
            container.alpha = entity.isOpen ? 0.3 : 1
        case .controlSwitch:
            shape = SKShapeNode(circleOfRadius: 22); stroke = UIColor(ColorPS.green)
            fill = stroke.withAlphaComponent(entity.isUsed ? 0.8 : 0.3); glyph = entity.isUsed ? "✓" : "⏻"
        case .portal:
            shape = SKShapeNode(circleOfRadius: 34); stroke = UIColor(ColorPS.violet)
            let inner = SKShapeNode(circleOfRadius: 23); inner.strokeColor = accent; inner.lineWidth = 3
            container.addChild(inner)
            glyph = entity.pair?.uppercased() ?? "P"
        case .crystal:
            let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: 39)); path.addLines(between: [CGPoint(x: 29, y: 8), CGPoint(x: 20, y: -27), CGPoint(x: 0, y: -39), CGPoint(x: -29, y: -8), CGPoint(x: -20, y: 27)]); path.closeSubpath()
            shape = SKShapeNode(path: path); stroke = UIColor(ColorPS.warning); fill = stroke.withAlphaComponent(0.15)
            glyph = entity.durability == 2 ? "Ⅱ" : "╱"
        case .core:
            shape = SKShapeNode(circleOfRadius: 29); fill = accent.withAlphaComponent(0.25); glyph = "✛"
        case .reactor:
            let path = CGMutablePath()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3
                let point = CGPoint(x: cos(angle) * 36, y: sin(angle) * 36)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath(); shape = SKShapeNode(path: path)
            fill = accent.withAlphaComponent(0.4); glyph = ""
        case .magnet:
            shape = SKShapeNode(circleOfRadius: 34); glyph = entity.polarity?.symbol ?? "+"
            let field = SKShapeNode(circleOfRadius: 43); field.strokeColor = accent.withAlphaComponent(0.22); field.lineWidth = 2
            container.addChild(field)
        case .polaritySwitch:
            shape = SKShapeNode(rectOf: CGSize(width: 72, height: 60), cornerRadius: 28)
            glyph = entity.polarity?.symbol ?? "+"; fill = accent.withAlphaComponent(0.22)
            let caption = SKLabelNode(fontNamed: "AvenirNext-Bold"); caption.text = "±"; caption.fontSize = 17; caption.fontColor = accent; caption.position = CGPoint(x: 29, y: -36); container.addChild(caption)
        }
        shape.fillColor = fill; shape.strokeColor = stroke; shape.lineWidth = entity.isShard ? 3 : 2
        shape.glowWidth = reduced || entity.kind == .wall ? 0 : (entity.isShard ? 4 : 2)
        shape.zPosition = -1; shape.name = "body"; container.addChild(shape)
        if entity.isShard, let texture = SpriteArtPS.named(entity.kind == .dormant ? "piece_dormant" : "piece_shard") ?? SpriteArtPS.shard(color: accent) {
            let face = SKSpriteNode(texture: texture); face.size = CGSize(width: 94, height: 94); face.zPosition = -0.5; face.name = "face"
            container.addChild(face)
            shape.lineWidth = 3; shape.glowWidth = reduced ? 0 : 6
        } else if let texture = SpriteArtPS.named("mechanic_\(entity.kind.rawValue)") {
            let art = SKSpriteNode(texture: texture); art.size = CGSize(width: 86, height: 86); art.zPosition = -0.4; container.addChild(art)
        }
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.name = "glyph"; label.text = glyph + "\u{FE0E}"; label.fontColor = entity.kind == .wall ? UIColor(ColorPS.muted) : stroke
        label.fontSize = entity.isShard ? 44 : 32; label.verticalAlignmentMode = .center
        container.addChild(label)
        if entity.isShard {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -17)); path.addLine(to: CGPoint(x: 0, y: 17))
            path.move(to: CGPoint(x: -12, y: 5)); path.addLine(to: CGPoint(x: 0, y: 17)); path.addLine(to: CGPoint(x: 12, y: 5))
            let arrow = SKShapeNode(path: path); arrow.name = "direction"; arrow.strokeColor = .white; arrow.lineWidth = 6
            arrow.zRotation = rotation(entity.direction); arrow.position.y = 3; container.addChild(arrow)
            if let texture = SpriteArtPS.named("piece_arrow_up") {
                arrow.strokeColor = .clear
                let art = SKSpriteNode(texture: texture); art.size = CGSize(width: 44, height: 44); arrow.addChild(art)
            }
        }
        if entity.kind == .reactor {
            for direction in entity.directions {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: 5)); path.addLine(to: CGPoint(x: 0, y: 24))
                path.move(to: CGPoint(x: -6, y: 17)); path.addLine(to: CGPoint(x: 0, y: 24)); path.addLine(to: CGPoint(x: 6, y: 17))
                let ray = SKShapeNode(path: path); ray.strokeColor = accent; ray.lineWidth = 3
                ray.zRotation = rotation(direction); container.addChild(ray)
            }
        }
        if entity.kind == .magnet {
            let axis = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            axis.text = "\(entity.axis == .horizontal ? "↔\u{FE0E}" : entity.axis == .vertical ? "↕\u{FE0E}" : "✛") \(entity.range)"
            axis.fontSize = 14; axis.fontColor = accent.withAlphaComponent(0.7); axis.position.y = -45; container.addChild(axis)
        }
        if (entity.kind == .rotator || entity.kind == .redirector), abs(entity.turns) == 2 {
            let turns = SKLabelNode(fontNamed: "AvenirNext-DemiBold"); turns.text = "180°"; turns.fontSize = 13; turns.fontColor = stroke; turns.position.y = -44; container.addChild(turns)
        }
        if entity.isShard, let polarity = entity.polarity {
            let sign = SKLabelNode(fontNamed: "AvenirNext-Bold"); sign.text = polarity.symbol; sign.fontSize = 17
            sign.fontColor = .white; sign.position = CGPoint(x: 24, y: 21); container.addChild(sign)
        }
        if !entity.links.isEmpty && entity.kind == .controlSwitch {
            let link = SKLabelNode(fontNamed: "AvenirNext-DemiBold"); link.text = entity.links.joined(separator: "·").replacingOccurrences(of: "gate", with: "G")
            link.fontSize = 13; link.fontColor = UIColor(ColorPS.secondary); link.position.y = -43; container.addChild(link)
        } else if entity.kind == .gate {
            let link = SKLabelNode(fontNamed: "AvenirNext-DemiBold"); link.text = entity.id.replacingOccurrences(of: "gate", with: "G")
            link.fontSize = 13; link.fontColor = UIColor(ColorPS.secondary); link.position.y = -43; container.addChild(link)
        }
        return container
    }
}
