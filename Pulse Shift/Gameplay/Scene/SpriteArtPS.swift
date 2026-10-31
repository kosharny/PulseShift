import SpriteKit
import SwiftUI

@MainActor enum SpriteArtPS {
    private static var cache: [String: SKTexture] = [:]
    static func color(for entity: LevelEntityPS, theme: ThemePS) -> UIColor {
        if let polarity = entity.polarity { return UIColor(polarity == .positive ? ColorPS.cyan : ColorPS.pink) }
        if theme.id != "dark" { return UIColor(entity.direction == .left || entity.direction == .down ? theme.secondary : theme.accent) }
        switch entity.direction {
        case .up: return UIColor(ColorPS.cyan)
        case .right: return UIColor(ColorPS.blue)
        case .down: return UIColor(ColorPS.violet)
        case .left: return UIColor(ColorPS.green)
        }
    }
    static func named(_ name: String) -> SKTexture? {
        guard UIImage(named: name) != nil else { return nil }
        if let cached = cache[name] { return cached }
        let texture = SKTexture(imageNamed: name); cache[name] = texture; return texture
    }
    static func shard(color: UIColor) -> SKTexture? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "shard-\(r)-\(g)-\(b)"
        if let cached = cache[key] { return cached }
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: 192, height: 192, bitsPerComponent: 8, bytesPerRow: 768, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let shadow = CGPath(roundedRect: CGRect(x: 12, y: 8, width: 168, height: 166), cornerWidth: 42, cornerHeight: 42, transform: nil)
        context.addPath(shadow); context.setFillColor(UIColor(red: r * 0.2, green: g * 0.3, blue: b * 0.45, alpha: 1).cgColor); context.fillPath()
        let face = CGPath(roundedRect: CGRect(x: 12, y: 23, width: 168, height: 157), cornerWidth: 40, cornerHeight: 40, transform: nil)
        context.saveGState(); context.addPath(face); context.clip()
        let colors = [UIColor(red: min(1, r + 0.27), green: min(1, g + 0.22), blue: min(1, b + 0.2), alpha: 1).cgColor,
                      color.cgColor, UIColor(red: r * 0.48, green: g * 0.57, blue: b * 0.75, alpha: 1).cgColor]
        if let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 0.45, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 65, y: 180), end: CGPoint(x: 115, y: 23), options: [])
        }
        context.setFillColor(UIColor.white.withAlphaComponent(0.19).cgColor)
        context.fillEllipse(in: CGRect(x: 2, y: 114, width: 191, height: 90))
        context.restoreGState()
        context.addPath(face); context.setStrokeColor(UIColor.white.withAlphaComponent(0.66).cgColor); context.setLineWidth(3); context.strokePath()
        let inner = CGPath(roundedRect: CGRect(x: 21, y: 31, width: 150, height: 140), cornerWidth: 33, cornerHeight: 33, transform: nil)
        context.addPath(inner); context.setStrokeColor(UIColor.white.withAlphaComponent(0.22).cgColor); context.setLineWidth(2); context.strokePath()
        guard let image = context.makeImage() else { return nil }
        let texture = SKTexture(cgImage: image); texture.filteringMode = .linear; cache[key] = texture; return texture
    }
}
