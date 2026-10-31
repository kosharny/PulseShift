import SwiftUI
import SpriteKit

struct GameContainerViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicType
    private var tip: String? {
        model.hintMessage ?? (model.settings.tutorialTips && model.boardState.moves == 0 ? model.currentLevel?.tutorialMessage : nil)
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                EnergyBackgroundPS(accent: model.theme.accent)
                VStack(spacing: 8) {
                    GameHUDViewPS()
                    ObjectiveStripPS().padding(.horizontal, 14)
                    board
                        .frame(width: boardSize(geometry.size).width, height: boardSize(geometry.size).height)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(model.theme.accent.opacity(0.38), lineWidth: 1.5))
                        .shadow(color: model.theme.accent.opacity(0.18), radius: 18, y: 8)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("game-arena")
                    if let tip {
                        HStack(spacing: 9) {
                            Image(systemName: model.hintMessage == nil ? "hand.tap.fill" : "lightbulb.fill").foregroundStyle(ColorPS.warning)
                            Text(tip).font(.system(.footnote, design: .rounded, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                        }.padding(.horizontal, 14).padding(.vertical, 9)
                            .background(ColorPS.card.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ColorPS.warning.opacity(0.25)))
                            .padding(.horizontal, 18).accessibilityIdentifier("tutorial")
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 12) {
                        GameActionButtonPS(title: "Undo", symbol: "arrow.uturn.backward", bright: false) { model.undo() }
                            .disabled(!model.canUndo || model.sessionState != .playing)
                        GameActionButtonPS(title: "Hint", symbol: "lightbulb.fill", bright: true) { model.hint() }
                            .disabled(model.sessionState != .playing)
                    }.padding(.horizontal, 18).padding(.bottom, 7)
                }
                .allowsHitTesting(model.sessionState == .playing || model.sessionState == .resolvingMove)
                if model.sessionState == .paused { PauseViewPS() }
                if model.sessionState == .completed, let result = model.result { LevelCompleteViewPS(result: result) }
                if model.sessionState == .failed { LevelFailedViewPS() }
            }
        }
    }
    private func boardSize(_ size: CGSize) -> CGSize {
        let ratio = CGFloat(model.currentLevel?.rows ?? 10) / CGFloat(model.currentLevel?.columns ?? 7)
        let reserve: CGFloat = (tip == nil ? 178 : 225) + (dynamicType.isAccessibilitySize ? 65 : 0)
        let height = max(150, min((size.width - 18) * ratio, size.height - reserve))
        return CGSize(width: height / ratio, height: height)
    }
    private var board: some View {
        SpriteView(scene: model.scene, preferredFramesPerSecond: 60, options: [.allowsTransparency], debugOptions: debugOptions)
            .accessibilityRepresentation {
                GeometryReader { geometry in
                    let layout = BoardLayoutPS(rows: model.currentLevel?.rows ?? 9, columns: model.currentLevel?.columns ?? 7, size: geometry.size)
                    ZStack(alignment: .topLeading) {
                        ForEach(model.boardState.entities) { entity in
                            let point = layout.point(entity.position)
                            Group {
                                if entity.isTappable {
                                    Button(accessibleLabel(entity)) { model.tap(entity.id) }
                                        .accessibilityHint(entity.id == model.hintedID ? "Recommended next move" : "Activate this signal")
                                        .disabled(model.sessionState != .playing)
                                } else { Text(accessibleLabel(entity)) }
                            }
                            .frame(width: layout.cell, height: layout.cell)
                            .position(x: point.x, y: geometry.size.height - point.y)
                        }
                    }
                }
            }
    }
    private func accessibleLabel(_ entity: LevelEntityPS) -> String {
        let name = entity.kind == .shard ? "Pulse \(entity.id)" : entity.kind == .polaritySwitch ? "Polarity switch \(entity.id)" : entity.kind.rawValue
        return "\(name), row \(entity.position.row + 1), column \(entity.position.column + 1), \(entity.direction.rawValue)\(entity.polarity.map { ", \($0.rawValue)" } ?? "")\(entity.kind == .gate ? (entity.isOpen ? ", open" : ", closed") : "")"
    }

    private var debugOptions: SpriteView.DebugOptions {
        #if DEBUG
        model.showFPS ? [.showsFPS, .showsNodeCount] : []
        #else
        []
        #endif
    }
}

struct GameHUDViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            IconButtonPS(symbol: "pause.fill", label: "Pause") { model.pause() }
            VStack(alignment: .leading, spacing: 3) {
                Text(model.isDailyMode ? "DAILY SHIFT" : "LEVEL \(String(format: "%02d", model.currentLevel?.id ?? 1))")
                    .font(.system(.headline, design: .rounded, weight: .black))
                Text(model.chapter.name).font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1).foregroundStyle(ColorPS.secondary)
            }
            Spacer(minLength: 0)
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(model.boardState.moves)").font(.system(size: 23, weight: .black, design: .rounded)).foregroundStyle(ColorPS.text)
                    Text("/ \(model.currentLevel?.parMoves ?? 0)").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(ColorPS.cyan)
                }.monospacedDigit().contentTransition(.numericText())
                Text(model.currentLevel?.maxMoves.map { "MAX \($0)" } ?? "MOVES / PAR")
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(ColorPS.secondary)
            }.padding(.horizontal, 12).padding(.vertical, 5).background(ColorPS.card, in: RoundedRectangle(cornerRadius: 14))
            IconButtonPS(symbol: "arrow.clockwise", label: "Restart") { model.restart() }
        }.padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 2)
    }
}

struct GameActionButtonPS: View {
    @Environment(\.isEnabled) private var isEnabled
    var title: String
    var symbol: String
    var bright: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 21, weight: .bold))
                Text(title).font(.system(.headline, design: .rounded, weight: .heavy))
            }.frame(maxWidth: .infinity).frame(height: 54)
                .foregroundStyle(bright ? ColorPS.background : ColorPS.text)
                .background(LinearGradient(colors: bright ? [ColorPS.warning, Color(hexPS: 0xFFB84D)] : [ColorPS.elevated, ColorPS.card], startPoint: .top, endPoint: .bottom), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(bright ? 0.35 : 0.13), lineWidth: 1.5))
                .shadow(color: (bright ? Color.orange : Color.black).opacity(0.3), radius: 0, y: 4)
                .opacity(isEnabled ? 1 : 0.35)
        }.buttonStyle(JuicyButtonStylePS())
    }
}

struct GameOverlayPS<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            EnergyBackgroundPS(accent: ColorPS.violet)
            ScrollView { VStack(spacing: 18) { content }.padding(22).frame(maxWidth: 480).frame(maxWidth: .infinity) }
                .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct PauseViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        GameOverlayPS {
            Image(systemName: "pause.circle").font(.system(size: 55, weight: .ultraLight)).foregroundStyle(ColorPS.cyan).padding(.top, 36)
            Text("PAUSED").font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(4)
            Text("Your signal is right where you left it.").font(.subheadline).foregroundStyle(ColorPS.secondary)
            GlassCardPS { HStack { StatChipPS(value: "\(model.boardState.moves)", label: "Moves"); StatChipPS(value: "\(model.currentLevel?.parMoves ?? 0)", label: "Par"); StatChipPS(value: "\(GameResultPS.stars(moves: model.boardState.moves, par: model.currentLevel?.parMoves ?? 1)) ★", label: "On track for") } }
            PrimaryButtonPS(title: "RESUME", symbol: "play.fill") { model.resume() }
            Button("Restart level") { model.restart() }
            Button("Settings") { model.sheet = .settings }
            Button("Exit to Home") { model.home() }.foregroundStyle(ColorPS.secondary)
        }.tint(ColorPS.cyan)
    }
}

struct LevelCompleteViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    @StateObject private var presentation = CompletionPresentationPS()
    let result: GameResultPS
    var body: some View {
        GameOverlayPS {
            VStack(spacing: 10) {
                Text("LEVEL COMPLETE").font(.system(.title, design: .rounded, weight: .black))
                Text(result.perfect ? "PERFECT SHIFT" : result.stars == 3 ? "GREAT SHIFT" : "NICE SHIFT")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(2).foregroundStyle(ColorPS.warning)
                HStack(alignment: .center, spacing: 16) {
                    ForEach(0..<3) { index in
                        AssetIconPS(name: "reward_star", fallback: "star.fill")
                            .frame(width: index == 1 ? 68 : 54, height: index == 1 ? 68 : 54)
                            .foregroundStyle(index < presentation.stars ? ColorPS.warning : ColorPS.elevated)
                            .shadow(color: ColorPS.warning.opacity(index < presentation.stars ? 0.55 : 0), radius: 15, y: 3)
                            .rotationEffect(.degrees(index == 0 ? -12 : index == 2 ? 12 : 0))
                            .scaleEffect(index < presentation.stars ? 1 : 0.65)
                            .offset(y: index == 1 ? -8 : 8)
                    }
                }.frame(height: 120).accessibilityElement(children: .ignore).accessibilityLabel("\(result.stars) stars")
                Text(result.perfect ? "You made it flow!" : "That’s a beautiful clear.").font(.system(.title3, design: .rounded, weight: .bold))
            }.padding(.top, 14).frame(maxWidth: .infinity)
                .background { CelebrationPS(started: presentation.started, stopped: presentation.finished || model.reduced) }
            GlassCardPS(accent: ColorPS.violet) {
                HStack {
                    StatChipPS(value: "\(result.moves)", label: "Moves")
                    StatChipPS(value: "\(result.par)", label: "Par")
                    StatChipPS(value: "×\(result.chain)", label: "Best chain")
                }
            }
            HStack(spacing: 14) {
                EventEmblemPS(asset: "reward_energy", symbol: "bolt.fill", color: ColorPS.warning, size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.earnedEnergy > 0 ? "+\(presentation.energy)" : "BEST SAVED")
                        .font(.system(.title, design: .rounded, weight: .black)).contentTransition(.numericText())
                    Text(model.earnedEnergy > 0 ? "Pulse Energy collected" : "Replay anytime to perfect your flow")
                        .font(.caption.weight(.semibold)).foregroundStyle(ColorPS.secondary)
                }
                Spacer()
            }.padding(18).background(ColorPS.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
            if let id = model.currentLevel?.id, id % 10 == 0, id < 60, !model.isDailyMode {
                GlassCardPS(accent: ColorPS.pink) {
                    Label("\(ChapterPS.all[id / 10].name) unlocked!", systemImage: "gift.fill").font(.headline).foregroundStyle(ColorPS.pink)
                }
            } else if model.currentLevel?.id == 60, !model.isDailyMode {
                Label("Full spectrum. All 60 signals connected!", systemImage: "crown.fill").font(.subheadline.bold()).foregroundStyle(ColorPS.warning)
            }
            PrimaryButtonPS(title: model.nextLabel) { model.next() }
                .disabled(presentation.stars < result.stars).accessibilityIdentifier("result-continue")
            HStack(spacing: 12) {
                GameActionButtonPS(title: "Replay", symbol: "arrow.clockwise") { model.restart() }
                GameActionButtonPS(title: "Home", symbol: "house.fill") { model.home() }
            }
        }.task {
            await presentation.reveal(stars: result.stars, reward: model.earnedEnergy, reduced: model.reduced)
            if !Task.isCancelled, model.earnedEnergy > 0 { model.rewardFeedback() }
        }
    }
}

struct CelebrationPS: View {
    let started: Date
    let stopped: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: stopped)) { timeline in
            Canvas { context, size in
                let age = min(1.8, timeline.date.timeIntervalSince(started))
                guard !stopped else { return }
                for index in 0..<36 {
                    let angle = Double(index) * 2.39996
                    let distance = age * Double(50 + index % 6 * 20)
                    let x = size.width / 2 + cos(angle) * distance
                    let y = size.height * 0.5 + sin(angle) * distance + age * age * 26
                    let colors = [ColorPS.cyan, ColorPS.warning, ColorPS.pink, ColorPS.green]
                    context.opacity = max(0, 1 - age / 1.8)
                    context.fill(Path(roundedRect: CGRect(x: x, y: y, width: index % 2 == 0 ? 5 : 8, height: 4), cornerRadius: 2), with: .color(colors[index % 4]))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct LevelFailedViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        GameOverlayPS {
            EventEmblemPS(asset: "completion_retry", symbol: "arrow.uturn.backward", color: ColorPS.warning, size: 92).padding(.top, 24)
            Text("SIGNAL LOST").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("So close! Try a different order, or undo to keep your good moves.").multilineTextAlignment(.center).foregroundStyle(ColorPS.secondary)
            PrimaryButtonPS(title: "TRY AGAIN", symbol: "arrow.clockwise") { model.restart() }
            GameActionButtonPS(title: "Undo last move", symbol: "arrow.uturn.backward") { model.undo() }.disabled(!model.canUndo)
            Button("Restart with a hint") { model.restart(); model.hint() }
            Button("Home") { model.home() }.foregroundStyle(ColorPS.secondary)
        }.tint(ColorPS.cyan)
    }
}

#Preview { LevelCompleteViewPS(result: .init(moves: 3, par: 3, chain: 9, seconds: 42, usedHint: false, usedUndo: false)).environment(PulseShiftViewModelPS(preview: true)).preferredColorScheme(.dark) }

#Preview("First Pulse") {
    let model = PulseShiftViewModelPS(preview: true)
    if let level = model.catalog.levels.first { model.start(level) }
    return RootViewPS().environment(model)
}

struct ObjectiveStripPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    private var targets: [(String, Int, String)] {
        guard let level = model.currentLevel else { return [] }
        return level.objectives.map { objective in
            switch objective {
            case .clearShards: return ("arrow.up", model.boardState.entities.filter(\.isShard).count, "Pulses remaining")
            case .destroyCrystals: return ("diamond.fill", model.boardState.entities.filter { $0.kind == .crystal }.count, "Crystals remaining")
            case .activateReactors: return ("bolt.shield.fill", level.entities.filter { $0.kind == .reactor && !model.boardState.activated.contains($0.id) }.count, "Reactors to ignite")
            case .usePortals: return ("circle.dotted", level.entities.filter { $0.kind == .portal && !model.boardState.portalsUsed.contains($0.id) }.count / 2, "Portal pairs to use")
            }
        }
    }
    var body: some View {
        HStack(spacing: 7) {
            Text(targets.count == 1 ? "Clear all pulses" : "Clear & connect").font(.system(.subheadline, design: .rounded, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            ForEach(Array(targets.enumerated()), id: \.offset) { _, target in
                HStack(spacing: 4) {
                    Image(systemName: target.1 == 0 ? "checkmark" : target.0).font(.caption.bold())
                    Text("\(target.1)").font(.system(.subheadline, design: .rounded, weight: .black)).monospacedDigit()
                }.foregroundStyle(target.1 == 0 ? ColorPS.green : ColorPS.cyan)
                    .padding(.horizontal, 8).padding(.vertical, 8)
                    .background(ColorPS.cyan.opacity(0.12), in: Capsule())
                    .accessibilityElement(children: .ignore).accessibilityLabel("\(target.2): \(target.1)")
            }
        }.frame(minHeight: 36)
    }
}
