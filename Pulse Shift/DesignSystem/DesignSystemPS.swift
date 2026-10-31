import SwiftUI

enum ColorPS {
    static let background = Color(hexPS: 0x071122)
    static let secondaryBackground = Color(hexPS: 0x0C1730)
    static let card = Color(hexPS: 0x17284A)
    static let elevated = Color(hexPS: 0x243C65)
    static let board = Color(hexPS: 0x112040)
    static let grid = Color(hexPS: 0x294774)
    static let text = Color(hexPS: 0xF7FAFF)
    static let secondary = Color(hexPS: 0xB1C7E8)
    static let muted = Color(hexPS: 0x8098BC)
    static let cyan = Color(hexPS: 0x35E6FF)
    static let blue = Color(hexPS: 0x49A5FF)
    static let violet = Color(hexPS: 0x8A6BFF)
    static let pink = Color(hexPS: 0xD95CFF)
    static let green = Color(hexPS: 0x5EFFA9)
    static let warning = Color(hexPS: 0xFFD95A)
    static let danger = Color(hexPS: 0xFF6A75)
}

extension Color {
    init(hexPS: UInt32) {
        self.init(.sRGB, red: Double((hexPS >> 16) & 255) / 255, green: Double((hexPS >> 8) & 255) / 255, blue: Double(hexPS & 255) / 255, opacity: 1)
    }
}

struct ThemePS: Identifiable {
    let id: String
    let name: String
    let description: String
    let accent: Color
    let secondary: Color
    let surface: Color
    let cost: Int
    static let all: [Self] = [
        .init(id: "dark", name: "DARK MATTER", description: "Cold cyan energy inside deep-space darkness.", accent: ColorPS.cyan, secondary: ColorPS.blue, surface: ColorPS.board, cost: 0),
        .init(id: "neon", name: "NEON VOID", description: "Violet pulses disappear into a black void.", accent: ColorPS.violet, secondary: ColorPS.pink, surface: Color(hexPS: 0x110B24), cost: 400),
        .init(id: "prism", name: "PRISM CORE", description: "A spectrum of light. A perfectly clear signal.", accent: ColorPS.pink, secondary: ColorPS.cyan, surface: Color(hexPS: 0x101323), cost: 600),
        .init(id: "solar", name: "SOLAR FLARE", description: "Warm gold pulses through dark graphite.", accent: Color(hexPS: 0xFFB54F), secondary: Color(hexPS: 0xFF6348), surface: Color(hexPS: 0x1C1510), cost: 250),
        .init(id: "frost", name: "FROST SIGNAL", description: "An icy frequency. Quiet, sharp, luminous.", accent: Color(hexPS: 0xB5F3FF), secondary: Color(hexPS: 0x77A9F7), surface: Color(hexPS: 0x0A1721), cost: 350)
    ]
}

struct GlassCardPS<Content: View>: View {
    var accent: Color = ColorPS.grid
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [ColorPS.elevated.opacity(0.8), ColorPS.card], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(LinearGradient(colors: [accent.opacity(0.8), Color.white.opacity(0.06), accent.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.23), radius: 10, y: 7)
    }
}

struct PrimaryButtonPS: View {
    @Environment(\.isEnabled) private var isEnabled
    var title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).font(.system(.headline, design: .rounded, weight: .bold)); Spacer(); Image(systemName: symbol).fontWeight(.bold) }
                .padding(.horizontal, 22).frame(minHeight: 60)
                .foregroundStyle(ColorPS.background)
                .background(LinearGradient(colors: [Color(hexPS: 0x8AF6FF), ColorPS.cyan, ColorPS.blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
                .overlay { OptionalArtworkPS(name: "ui_cta").clipShape(RoundedRectangle(cornerRadius: 22)) }
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.45), lineWidth: 1.5))
                .shadow(color: ColorPS.blue.opacity(0.55), radius: 0, y: 5)
                .shadow(color: ColorPS.cyan.opacity(0.22), radius: 13, y: 6)
        }.buttonStyle(JuicyButtonStylePS()).opacity(isEnabled ? 1 : 0.45)
    }
}

struct StatChipPS: View {
    var value: String
    var label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(ColorPS.text).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(ColorPS.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionTitlePS: View {
    var title: String
    var detail: String = ""
    var body: some View {
        HStack {
            Text(title).font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(0.6).foregroundStyle(ColorPS.secondary)
            Spacer()
            if !detail.isEmpty { Text(detail).font(.caption).foregroundStyle(ColorPS.muted) }
        }.padding(.top, 8)
    }
}

struct IconButtonPS: View {
    var symbol: String
    var label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 19, weight: .bold)).frame(width: 44, height: 44).background(LinearGradient(colors: [ColorPS.elevated, ColorPS.card], startPoint: .top, endPoint: .bottom), in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.16))).shadow(color: .black.opacity(0.3), radius: 0, y: 3) }
            .buttonStyle(JuicyButtonStylePS()).foregroundStyle(ColorPS.text).accessibilityLabel(label)
    }
}

#Preview { VStack { GlassCardPS { StatChipPS(value: "128", label: "Pulse Energy") }; PrimaryButtonPS(title: "CONTINUE") {} }.padding().background(ColorPS.background) }
