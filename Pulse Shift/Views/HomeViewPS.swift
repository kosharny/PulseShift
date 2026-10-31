import SwiftUI

struct HomeViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Find your flow.").font(.system(.title, design: .rounded, weight: .black))
                Spacer()
                RewardBadgePS(value: "\(model.persistence.player.energy)")
            }
            HStack(spacing: 8) {
                RewardBadgePS(value: "\(model.streak) day streak", symbol: "flame.fill", color: ColorPS.pink)
                Text("One smart move changes everything.").font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(ColorPS.secondary)
            }
            if let level = model.nextLevel {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("CHAPTER \(String(format: "%02d", level.chapter))").font(.system(.caption, design: .rounded, weight: .black)).tracking(1.5)
                            .padding(.horizontal, 12).padding(.vertical, 7).background(.white.opacity(0.12), in: Capsule())
                        Spacer()
                        Label("\(model.chapterStars(level.chapter)) / 30", systemImage: "star.fill").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(ColorPS.warning)
                    }
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Level \(String(format: "%02d", level.id))").font(.system(size: 43, weight: .black, design: .rounded)).minimumScaleFactor(0.75).lineLimit(1)
                            Text(ChapterPS.all[level.chapter - 1].name).font(.system(.subheadline, design: .rounded, weight: .heavy)).foregroundStyle(ColorPS.cyan)
                            Text(level.name).font(.subheadline).foregroundStyle(ColorPS.secondary)
                        }
                        Spacer(minLength: 2)
                        MiniBoardPS(theme: model.theme).frame(width: 120, height: 132).rotationEffect(.degrees(-9))
                    }
                    HStack(spacing: 12) {
                        ProgressView(value: Double(model.campaignRecords.filter { ($0.levelID - 1) / 10 + 1 == level.chapter }.count), total: 10).tint(ColorPS.green)
                        Text("\(model.campaignRecords.filter { ($0.levelID - 1) / 10 + 1 == level.chapter }.count)/10").font(.caption.bold()).foregroundStyle(ColorPS.secondary)
                    }
                    PrimaryButtonPS(title: "CONTINUE", symbol: "play.fill") { model.interfaceFeedback(); model.start(level) }
                }.padding(22)
                    .background(LinearGradient(colors: [Color(hexPS: 0x284D84), Color(hexPS: 0x24356B), Color(hexPS: 0x202B51)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30))
                    .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(LinearGradient(colors: [ColorPS.cyan.opacity(0.8), ColorPS.violet.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                    .shadow(color: ColorPS.blue.opacity(0.15), radius: 16, y: 7)
            }
            SectionTitlePS(title: "TODAY’S ADVENTURE", detail: "Fresh rewards")
            Button { model.interfaceFeedback(); model.tab = .daily } label: {
                GlassCardPS(accent: ColorPS.violet) {
                    HStack(spacing: 10) {
                        EventEmblemPS(asset: "home_daily", symbol: "waveform.path", color: ColorPS.violet).frame(width: 76, height: 76)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("DAILY SHIFT").font(.system(.caption, design: .rounded, weight: .heavy)).foregroundStyle(ColorPS.pink)
                            Text(model.daily?.level.name ?? "New signal soon").font(.system(.title3, design: .rounded, weight: .bold))
                            Label("+75 bonus energy", systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(ColorPS.warning)
                        }
                        Spacer(minLength: 0); Image(systemName: "chevron.right").fontWeight(.black).foregroundStyle(ColorPS.violet)
                    }
                }
            }.buttonStyle(JuicyButtonStylePS())
            Button { model.interfaceFeedback(); model.sheet = .weekly } label: {
                GlassCardPS(accent: ColorPS.green.opacity(0.65)) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            EventEmblemPS(asset: "home_weekly", symbol: "point.3.connected.trianglepath.dotted", color: ColorPS.green).frame(width: 66, height: 66)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("WEEKLY CIRCUIT").font(.system(.headline, design: .rounded, weight: .heavy))
                                Text("Seven stages. One big payoff.").font(.caption).foregroundStyle(ColorPS.secondary)
                            }
                            Spacer(minLength: 0)
                            Text("\(model.weeklyCompleted)/7").font(.system(.title3, design: .rounded, weight: .black)).foregroundStyle(ColorPS.green)
                        }
                        HStack(spacing: 7) {
                            ForEach(0..<7) { index in
                                ZStack { Capsule().fill(index < model.weeklyCompleted ? ColorPS.green : ColorPS.elevated).frame(height: 9); if index == model.weeklyCompleted { Circle().fill(ColorPS.green).frame(width: 11, height: 11).shadow(color: ColorPS.green, radius: 4) } }
                            }
                        }
                    }
                }
            }.buttonStyle(JuicyButtonStylePS())
            HStack { SectionTitlePS(title: "YOUR SIGNAL"); Button("View all") { model.sheet = .statistics }.font(.subheadline.bold()).tint(ColorPS.cyan) }
            HStack(spacing: 10) {
                SignalStatCardPS(value: "\(model.totalStars)", title: "Stars", symbol: "star.fill", color: ColorPS.warning)
                SignalStatCardPS(value: "\(model.perfectClears)", title: "Perfect", symbol: "sparkles", color: ColorPS.pink)
                SignalStatCardPS(value: "×\(model.persistence.player.bestChain)", title: "Best chain", symbol: "bolt.fill", color: ColorPS.cyan)
            }
            Button { model.tab = .collection } label: {
                GlassCardPS(accent: ColorPS.pink.opacity(0.5)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Find your wavelength").font(.system(.title3, design: .rounded, weight: .heavy))
                            Text("Five worlds of color. Earn energy and make one yours.").font(.subheadline).foregroundStyle(ColorPS.secondary)
                            Label("EXPLORE THEMES", systemImage: "arrow.right").font(.caption.bold()).foregroundStyle(ColorPS.pink)
                        }
                        MiniBoardPS(theme: ThemePS.all[1]).frame(width: 90, height: 108).rotationEffect(.degrees(8))
                    }
                }
            }.buttonStyle(JuicyButtonStylePS())
            if let next = ChapterPS.all.first(where: { $0.id == (model.nextLevel?.chapter ?? 1) + 1 }) {
                HStack(spacing: 12) {
                    AssetIconPS(name: "chapter_0\(next.id)", fallback: next.symbol).frame(width: 24, height: 24).foregroundStyle(ColorPS.warning)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NEXT UNLOCK · \(next.name)").font(.system(.caption, design: .rounded, weight: .heavy)).foregroundStyle(ColorPS.warning)
                        Text("Clear Chapter \(next.id - 1) to discover a new twist.").font(.caption).foregroundStyle(ColorPS.secondary)
                    }
                }.padding(.vertical, 8)
            }
        }
    }
}

struct SignalStatCardPS: View {
    var value: String
    var title: String
    var symbol: String
    var color: Color
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: symbol).font(.system(size: 20, weight: .heavy)).foregroundStyle(color)
            Text(value).font(.system(.title2, design: .rounded, weight: .black)).monospacedDigit()
            Text(title).font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(ColorPS.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(LinearGradient(colors: [color.opacity(0.16), ColorPS.card], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(color.opacity(0.2)))
    }
}

struct MiniBoardPS: View {
    var theme: ThemePS = ThemePS.all[0]
    var body: some View {
        if UIImage(named: "theme_\(theme.id)_preview") != nil { Image("theme_\(theme.id)_preview").resizable().scaledToFit() }
        else {
            Canvas { context, size in
                let cell = min(size.width / 3, size.height / 4)
                let origin = CGPoint(x: (size.width - cell * 3) / 2, y: (size.height - cell * 4) / 2)
                let colors = [theme.accent, theme.secondary, ColorPS.green, ColorPS.warning]
                for row in 0..<4 {
                    for column in 0..<3 {
                        let rect = CGRect(x: origin.x + CGFloat(column) * cell + 4, y: origin.y + CGFloat(row) * cell + 4, width: cell - 7, height: cell - 7)
                        let active = (row + column * 2) % 4 != 1
                        let color = colors[(row + column) % colors.count]
                        let path = Path(roundedRect: rect, cornerRadius: cell * 0.23)
                        context.fill(Path(roundedRect: rect.offsetBy(dx: 0, dy: 3), cornerRadius: cell * 0.23), with: .color(.black.opacity(0.3)))
                        context.fill(path, with: .linearGradient(Gradient(colors: active ? [color, color.opacity(0.55)] : [ColorPS.elevated, theme.surface]), startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                        context.stroke(path, with: .color(active ? .white.opacity(0.6) : ColorPS.grid), lineWidth: 1)
                        if active { context.draw(Text(["↑", "→", "←", "↓"][(row + column) % 4]).font(.system(size: cell * 0.65, weight: .black)).foregroundStyle(.white), at: CGPoint(x: rect.midX, y: rect.midY)) }
                    }
                }
            }.accessibilityHidden(true)
        }
    }
}

extension ChapterPS {
    var color: Color { [ColorPS.cyan, ColorPS.blue, ColorPS.green, ColorPS.violet, ColorPS.pink, ColorPS.warning][id - 1] }
}

struct ChaptersViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let chapterID = model.selectedChapter, let chapter = ChapterPS.all.first(where: { $0.id == chapterID }) {
                Button { model.selectedChapter = nil } label: { Label("All chapters", systemImage: "chevron.left").font(.headline) }.tint(chapter.color)
                ChapterBannerPS(chapter: chapter, stars: model.chapterStars(chapter.id), unlocked: true)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                    ForEach(model.catalog.levels.filter { $0.chapter == chapter.id }) { level in
                        let available = model.unlocked(level.id)
                        let current = level.id == model.nextLevel?.id
                        Button { model.interfaceFeedback(); model.start(level) } label: {
                            VStack(spacing: 9) {
                                if available {
                                    Text(String(format: "%02d", level.id)).font(.system(.largeTitle, design: .rounded, weight: .black))
                                    HStack(spacing: 4) { ForEach(0..<3) { star in
                                        Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(star < (model.record(level.id)?.stars ?? 0) ? ColorPS.warning : ColorPS.muted.opacity(0.35))
                                    } }
                                    Text(current ? "PLAY" : level.id % 10 == 0 ? "FINALE" : model.record(level.id) != nil ? "CLEARED" : "READY")
                                        .font(.system(size: 9, weight: .heavy)).tracking(1).foregroundStyle(current ? ColorPS.background : chapter.color)
                                } else {
                                    Image(systemName: "lock.fill").font(.title2)
                                    Text(String(format: "%02d", level.id)).font(.headline)
                                }
                            }.frame(maxWidth: .infinity).frame(height: 118)
                                .foregroundStyle(current ? ColorPS.background : available ? ColorPS.text : ColorPS.muted)
                                .background(LinearGradient(colors: current ? [chapter.color, chapter.color.opacity(0.65)] : [ColorPS.elevated, ColorPS.card], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
                                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(current ? .white.opacity(0.5) : chapter.color.opacity(available ? 0.4 : 0.1), lineWidth: 1.5))
                                .shadow(color: current ? chapter.color.opacity(0.3) : .black.opacity(0.3), radius: current ? 10 : 0, y: 5)
                        }.buttonStyle(JuicyButtonStylePS()).disabled(!available)
                            .accessibilityLabel("Level \(level.id), \(model.record(level.id)?.stars ?? 0) stars")
                    }
                }
            } else {
                Text("Follow the signal.").font(.system(.largeTitle, design: .rounded, weight: .black))
                Text("60 puzzles. Six new ways to think.").foregroundStyle(ColorPS.secondary)
                ForEach(ChapterPS.all) { chapter in
                    let available = model.unlocked((chapter.id - 1) * 10 + 1)
                    Button { model.interfaceFeedback(); model.selectedChapter = chapter.id } label: {
                        ChapterBannerPS(chapter: chapter, stars: model.chapterStars(chapter.id), unlocked: available)
                    }.buttonStyle(JuicyButtonStylePS()).disabled(!available)
                }
            }
        }
    }
}

struct ChapterBannerPS: View {
    let chapter: ChapterPS
    let stars: Int
    let unlocked: Bool
    var body: some View {
        GlassCardPS(accent: chapter.color) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    EventEmblemPS(asset: "chapter_0\(chapter.id)", symbol: chapter.symbol, color: chapter.color, size: 68)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CHAPTER 0\(chapter.id)").font(.caption.weight(.heavy)).tracking(1.8).foregroundStyle(chapter.color)
                        Text(chapter.name).font(.system(.title2, design: .rounded, weight: .black))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: unlocked ? "chevron.right" : "lock.fill").foregroundStyle(chapter.color)
                }
                HStack(spacing: 16) {
                    Text(unlocked ? chapter.subtitle : "Complete Level \((chapter.id - 1) * 10) to unlock").font(.subheadline.weight(.medium)).foregroundStyle(ColorPS.secondary)
                    Spacer(minLength: 0)
                    MiniBoardPS(theme: ThemePS.all[(chapter.id - 1) % 5]).frame(width: 95, height: 76).rotationEffect(.degrees(-6))
                }
                HStack {
                    ProgressView(value: Double(stars), total: 30).tint(chapter.color)
                    RewardBadgePS(value: "\(stars)/30", symbol: "star.fill", color: ColorPS.warning)
                }
            }
        }.opacity(unlocked ? 1 : 0.72)
    }
}

#Preview { ScrollView { HomeViewPS().padding(24) }.background(ColorPS.background).environment(PulseShiftViewModelPS(preview: true)).preferredColorScheme(.dark) }
