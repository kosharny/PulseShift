import SwiftUI

struct DailyChallengeViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("A daily shift.").font(.system(.largeTitle, design: .rounded, weight: .black))
                Spacer()
                RewardBadgePS(value: "\(model.streak)", symbol: "flame.fill", color: ColorPS.warning)
            }
            Text(model.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).foregroundStyle(ColorPS.secondary)
            if let daily = model.daily {
                let completed = model.dailyDays.contains(daily.key)
                GlassCardPS(accent: ColorPS.violet) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack { Label(completed ? "SIGNAL CLEARED" : "TODAY’S FREQUENCY", systemImage: completed ? "checkmark.seal.fill" : "waveform.path").font(.caption.bold()).tracking(1).foregroundStyle(ColorPS.violet); Spacer() }
                        ZStack(alignment: .bottomTrailing) {
                            MiniBoardPS(theme: ThemePS.all[1]).frame(height: 178).frame(maxWidth: .infinity).rotationEffect(.degrees(-4))
                            EventEmblemPS(asset: "home_daily", symbol: "sun.max.fill", color: ColorPS.warning)
                        }.padding(.vertical, 8)
                        RewardBadgePS(value: completed ? "REWARD COLLECTED" : "+75 DAILY BONUS", symbol: "gift.fill", color: ColorPS.warning)
                        Text(daily.level.name).font(.system(.title, design: .rounded, weight: .bold))
                        HStack { StatChipPS(value: daily.level.chapter >= 5 ? "Hard" : "Medium", label: "Difficulty"); StatChipPS(value: "\(daily.level.parMoves)", label: "Par"); StatChipPS(value: "+75", label: "Energy bonus") }
                        if let record = model.persistence.records.first(where: { $0.key == "daily-\(daily.key)" }) {
                            Text("Best: \(record.bestMoves) moves · \(record.stars) stars\(record.perfect ? " · Perfect" : "")").font(.subheadline).foregroundStyle(ColorPS.green)
                        }
                        PrimaryButtonPS(title: completed ? "REPLAY DAILY" : "PLAY DAILY") { model.startDaily() }
                        if completed { Text("Replay freely. Today’s reward is already collected.").font(.caption).foregroundStyle(ColorPS.secondary) }
                    }
                }
            } else { GlassCardPS { Label("Today’s signal is unavailable. Campaign levels are ready in Levels.", systemImage: "waveform.path").foregroundStyle(ColorPS.secondary) } }
            SectionTitlePS(title: "KEEP YOUR FREQUENCY", detail: "\(model.streak) day streak")
            HStack(spacing: 7) {
                ForEach(-6...0, id: \.self) { offset in
                    if let date = Calendar.current.date(byAdding: .day, value: offset, to: model.now) {
                        let completed = model.dailyDays.contains(model.dailyService.dayKey(date))
                        VStack(spacing: 12) {
                            Text(date.formatted(.dateTime.weekday(.narrow))).font(.caption).foregroundStyle(ColorPS.secondary)
                            Image(systemName: completed ? "checkmark" : (offset == 0 ? "circle.dotted" : "minus")).font(.system(size: 16, weight: .bold)).foregroundStyle(completed ? ColorPS.cyan : ColorPS.muted)
                        }.frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: completed ? [ColorPS.green.opacity(0.32), ColorPS.card] : [ColorPS.elevated, ColorPS.card], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(offset == 0 ? ColorPS.warning : .clear))
                            .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(completed ? "completed" : "not completed")")
                    }
                }
            }
            Button { model.sheet = .weekly } label: { GlassCardPS { HStack { VStack(alignment: .leading, spacing: 6) { Text("WEEKLY CIRCUIT").font(.headline); Text("Seven stages. One connected journey.").font(.caption).foregroundStyle(ColorPS.secondary) }; Spacer(); Image(systemName: "arrow.right").foregroundStyle(ColorPS.cyan) } } }.buttonStyle(JuicyButtonStylePS())
        }
    }
}

struct WeeklyChallengeViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Weekly Circuit").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Build momentum. Complete seven connected stages before a new circuit begins.").foregroundStyle(ColorPS.secondary)
            GlassCardPS(accent: ColorPS.pink) {
                VStack(spacing: 20) {
                    HStack {
                        EventEmblemPS(asset: "home_weekly", symbol: "point.3.connected.trianglepath.dotted", color: ColorPS.pink)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GO THE DISTANCE").font(.headline).foregroundStyle(ColorPS.pink)
                            Text("\(model.weeklyCompleted) of 7 stages connected").font(.subheadline).foregroundStyle(ColorPS.secondary)
                            RewardBadgePS(value: "+150 FINAL BONUS", symbol: "gift.fill", color: ColorPS.warning)
                        }
                    }
                    ProgressView(value: Double(model.weeklyCompleted), total: 7).tint(ColorPS.pink)
                }
            }
            ForEach(0..<7) { stage in
                Button { model.startWeekly(stage) } label: {
                    HStack(spacing: 18) {
                        ZStack {
                            Circle().fill(stage <= model.weeklyCompleted ? ColorPS.cyan.opacity(0.12) : ColorPS.card).frame(width: 52, height: 52)
                            if stage < model.weeklyCompleted { Image(systemName: "checkmark").foregroundStyle(ColorPS.cyan) }
                            else if stage == model.weeklyCompleted { Text("\(stage + 1)").foregroundStyle(ColorPS.cyan).font(.title3.bold()) }
                            else { Image(systemName: "lock").foregroundStyle(ColorPS.muted) }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(["First Contact", "Change Direction", "Close the Circuit", "Phase Crossing", "Magnetic Field", "Chain Reaction", "Full Frequency"][stage]).font(.headline)
                            Text(stage < model.weeklyCompleted ? "Complete · Tap to replay" : stage == model.weeklyCompleted ? "Ready to connect" : "Complete stage \(stage) first").font(.caption).foregroundStyle(ColorPS.secondary)
                        }
                        Spacer()
                        if stage == model.weeklyCompleted { Image(systemName: "arrow.right").foregroundStyle(ColorPS.cyan) }
                    }.padding(16).background(LinearGradient(colors: stage == model.weeklyCompleted ? [ColorPS.violet.opacity(0.5), ColorPS.card] : [ColorPS.card, ColorPS.secondaryBackground], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(stage == model.weeklyCompleted ? ColorPS.pink.opacity(0.7) : ColorPS.grid))
                }.buttonStyle(JuicyButtonStylePS()).disabled(stage > model.weeklyCompleted)
            }
        }
    }
}

struct CollectionViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("Your wavelength.").font(.system(.largeTitle, design: .rounded, weight: .bold)); Spacer() }
            HStack { Text("Same precision. A different energy.").foregroundStyle(ColorPS.secondary); Spacer(); Label("\(model.persistence.player.energy)", systemImage: "bolt.fill").font(.subheadline.bold()).foregroundStyle(ColorPS.cyan) }
            ForEach(ThemePS.all) { theme in
                GlassCardPS(accent: model.settings.themeID == theme.id ? theme.accent : ColorPS.grid) {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                RadialGradient(colors: [theme.accent.opacity(0.3), theme.surface], center: .center, startRadius: 5, endRadius: 180)
                                MiniBoardPS(theme: theme).frame(width: 195, height: 170).rotationEffect(.degrees(-6)).padding(.top, 20)
                                if !model.owns(theme) {
                                    Image(systemName: "lock.fill").font(.title2).padding(17)
                                        .background(.ultraThinMaterial, in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.25)))
                                }
                            }.frame(height: 205).clipShape(RoundedRectangle(cornerRadius: 24))
                            RewardBadgePS(value: model.settings.themeID == theme.id ? "SELECTED" : model.owns(theme) ? "OWNED" : "\(theme.cost) ENERGY", symbol: model.settings.themeID == theme.id ? "checkmark.seal.fill" : "bolt.fill", color: theme.accent).padding(12)
                        }
                        Text(theme.name).font(.system(.title3, design: .rounded, weight: .bold)).tracking(2)
                        Text(theme.description).font(.subheadline).foregroundStyle(ColorPS.secondary)
                        HStack(spacing: 8) {
                            Circle().fill(theme.accent).frame(width: 15, height: 15)
                            Circle().fill(theme.secondary).frame(width: 15, height: 15)
                            Text(theme.cost == 0 ? "Your original signal · Included" : "Earn Pulse Energy by clearing puzzles")
                                .font(.caption).foregroundStyle(ColorPS.secondary)
                        }
                        Button { model.selectTheme(theme) } label: {
                            HStack { Text(model.settings.themeID == theme.id ? "Selected" : model.owns(theme) ? "Use theme" : model.persistence.player.energy >= theme.cost ? "Unlock · \(theme.cost) energy" : "Earn \(theme.cost - model.persistence.player.energy) more energy"); Spacer(); Image(systemName: model.owns(theme) ? "checkmark" : "bolt.fill") }.font(.subheadline.bold()).padding(15).foregroundStyle(theme.accent).background(theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(JuicyButtonStylePS()).disabled(model.settings.themeID == theme.id || (!model.owns(theme) && model.persistence.player.energy < theme.cost))
                    }
                }
            }
        }
    }
}

struct StatisticsViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Your signal.").font(.system(.largeTitle, design: .rounded, weight: .bold))
            GlassCardPS(accent: ColorPS.cyan) {
                HStack { StatChipPS(value: "\(model.campaignRecords.count) / 60", label: "Levels completed"); StatChipPS(value: "\(model.totalStars) / 180", label: "Total stars") }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, item in
                    SignalStatCardPS(value: item.1, title: item.0, symbol: ["star.fill", "bolt.fill", "flame.fill", "trophy.fill"][index % 4], color: [ColorPS.warning, ColorPS.cyan, ColorPS.pink, ColorPS.green][index % 4])
                }
            }
            GlassCardPS(accent: ColorPS.violet) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("YOUR CHAPTERS").font(.headline)
                    HStack(alignment: .bottom, spacing: 14) {
                        ForEach(ChapterPS.all) { chapter in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 8).fill(chapter.color.gradient)
                                    .frame(height: max(8, CGFloat(model.chapterStars(chapter.id)) / 30 * 100))
                                Text("0\(chapter.id)").font(.caption.bold()).foregroundStyle(ColorPS.secondary)
                            }.frame(maxWidth: .infinity)
                                .accessibilityLabel("Chapter \(chapter.id), \(model.chapterStars(chapter.id)) stars")
                        }
                    }.frame(height: 125, alignment: .bottom)
                }
            }
            SectionTitlePS(title: "ACHIEVEMENTS", detail: "\(model.achievements.filter(\.unlocked).count) / \(model.achievements.count)")
            ForEach(model.achievements) { achievement in
                GlassCardPS {
                    HStack(spacing: 16) {
                        Image(systemName: achievement.symbol).font(.title2).foregroundStyle(achievement.unlocked ? ColorPS.cyan : ColorPS.muted).frame(width: 32)
                        VStack(alignment: .leading, spacing: 7) {
                            HStack { Text(achievement.title).font(.headline); Spacer(); if achievement.unlocked { Image(systemName: "checkmark.seal.fill").foregroundStyle(ColorPS.cyan) } }
                            Text(achievement.description).font(.caption).foregroundStyle(ColorPS.secondary)
                            ProgressView(value: Double(min(achievement.target, achievement.value)), total: Double(achievement.target)).tint(ColorPS.cyan)
                        }
                    }
                }
            }
        }
    }
    private var stats: [(String, String)] {
        let p = model.persistence.player
        let completedWeeks = Dictionary(grouping: model.persistence.records.filter { $0.key.hasPrefix("weekly-") }, by: { String($0.key.dropLast(2)) }).values.filter { $0.count == 7 }.count
        return [("Perfect clears", "\(model.perfectClears)"), ("Best chain", "×\(p.bestChain)"), ("Current streak", "\(model.streak) days"), ("Longest streak", "\(p.bestStreak) days"), ("Total moves", "\(p.totalMoves)"), ("Avg. moves over par", String(format: "%.1f", p.completions == 0 ? 0 : Double(p.overPar) / Double(p.completions))), ("Hints used", "\(p.hints)"), ("Restarts", "\(p.restarts)"), ("Daily clears", "\(model.dailyDays.count)"), ("Weekly circuits", "\(completedWeeks)"), ("Play sessions", "\(p.sessions)"), ("Pulse Energy", "\(p.energy)")]
    }
}

#Preview { ScrollView { DailyChallengeViewPS().padding(24) }.background(ColorPS.background).environment(PulseShiftViewModelPS(preview: true)).preferredColorScheme(.dark) }
