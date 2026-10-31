import SwiftUI

struct JuicyButtonStylePS: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.965 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .brightness(configuration.isPressed ? 0.07 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct EnergyBackgroundPS: View {
    var accent: Color = ColorPS.cyan
    var body: some View {
        ZStack {
            LinearGradient(colors: [ColorPS.secondaryBackground, ColorPS.background], startPoint: .topLeading, endPoint: .bottomTrailing)
            OptionalArtworkPS(name: "background_energy")
            GeometryReader { geometry in
                Circle().fill(RadialGradient(colors: [accent.opacity(0.2), .clear], center: .center, startRadius: 5, endRadius: geometry.size.width * 0.65))
                    .frame(width: geometry.size.width * 1.3, height: geometry.size.width * 1.3).offset(x: -geometry.size.width * 0.55, y: -80)
                Circle().fill(RadialGradient(colors: [ColorPS.violet.opacity(0.14), .clear], center: .center, startRadius: 5, endRadius: geometry.size.width * 0.6))
                    .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2).position(x: geometry.size.width, y: geometry.size.height * 0.67)
                Canvas { context, size in
                    for i in 0..<18 {
                        let x = CGFloat((i * 71 + 29) % 337) / 337 * size.width
                        let y = CGFloat((i * 113 + 53) % 829) / 829 * size.height
                        let rect = CGRect(x: x, y: y, width: i % 4 == 0 ? 4 : 2, height: i % 4 == 0 ? 4 : 2)
                        context.fill(Path(ellipseIn: rect), with: .color(accent.opacity(i % 4 == 0 ? 0.3 : 0.12)))
                    }
                }
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct RewardBadgePS: View {
    var value: String
    var symbol: String = "bolt.fill"
    var color: Color = ColorPS.warning
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 15, weight: .black))
            Text(value).font(.system(.subheadline, design: .rounded, weight: .black)).monospacedDigit()
        }.foregroundStyle(color).padding(.horizontal, 12).padding(.vertical, 8)
            .background(LinearGradient(colors: [color.opacity(0.2), color.opacity(0.07)], startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.3)))
    }
}
