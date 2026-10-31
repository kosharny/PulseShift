import SwiftUI

struct AssetIconPS: View {
    let name: String
    let fallback: String
    var body: some View {
        if UIImage(named: name) != nil { Image(name).resizable().scaledToFit() }
        else { Image(systemName: fallback).resizable().scaledToFit() }
    }
}

struct PulseMarkPS: View {
    var body: some View {
        if UIImage(named: "branding_symbol") != nil { Image("branding_symbol").resizable().scaledToFit() }
        else {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    RoundedRectangle(cornerRadius: size.width * 0.28).fill(LinearGradient(colors: [ColorPS.cyan, ColorPS.blue, ColorPS.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Path { path in
                        path.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.6))
                        path.addLines([CGPoint(x: size.width * 0.4, y: size.height * 0.6), CGPoint(x: size.width * 0.52, y: size.height * 0.25), CGPoint(x: size.width * 0.52, y: size.height * 0.76), CGPoint(x: size.width * 0.65, y: size.height * 0.43), CGPoint(x: size.width * 0.84, y: size.height * 0.43)])
                    }.stroke(.white, style: StrokeStyle(lineWidth: size.width * 0.09, lineCap: .round, lineJoin: .round))
                }.overlay(RoundedRectangle(cornerRadius: size.width * 0.28).strokeBorder(.white.opacity(0.4)))
            }.shadow(color: ColorPS.cyan.opacity(0.3), radius: 8, y: 3)
        }
    }
}

struct EventEmblemPS: View {
    var asset: String
    var symbol: String
    var color: Color
    var size: CGFloat = 82
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.1)).frame(width: 82, height: 82)
            RoundedRectangle(cornerRadius: 23).fill(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 58, height: 58).rotationEffect(.degrees(-10))
                .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(.white.opacity(0.3)).frame(width: 58, height: 58).rotationEffect(.degrees(-10)))
            AssetIconPS(name: asset, fallback: symbol).frame(width: 29, height: 29).foregroundStyle(.white)
            Image(systemName: "sparkle").font(.system(size: 12, weight: .bold)).foregroundStyle(color).offset(x: 32, y: -28)
        }.frame(width: 82, height: 82).scaleEffect(size / 82).frame(width: size, height: size).shadow(color: color.opacity(0.3), radius: 9, y: 5).accessibilityHidden(true)
    }
}

struct OptionalArtworkPS: View {
    let name: String
    var body: some View {
        if UIImage(named: name) != nil { Image(name).resizable().scaledToFill().allowsHitTesting(false).accessibilityHidden(true) }
    }
}
