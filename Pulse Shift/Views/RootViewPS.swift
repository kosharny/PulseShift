import SwiftUI

struct RootViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        @Bindable var model = model
        ZStack {
            EnergyBackgroundPS()
            if model.isLaunching {
                VStack(spacing: 22) {
                    PulseMarkPS().frame(width: 82, height: 82)
                    Text("PULSE SHIFT").font(.system(.title, design: .rounded, weight: .black)).tracking(5)
                }
            } else if model.currentLevel != nil { GameContainerViewPS() }
            else {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        PulseMarkPS().frame(width: 35, height: 39)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PULSE SHIFT").font(.system(.headline, design: .rounded, weight: .black)).tracking(2)
                            Text("SMALL SHIFTS. BIG REACTIONS.").font(.system(size: 10, weight: .medium)).tracking(1.3).foregroundStyle(ColorPS.muted)
                        }
                        Spacer()
                        IconButtonPS(symbol: "gearshape", label: "Settings") { model.sheet = .settings }
                    }.padding(.horizontal, 20).padding(.vertical, 12)
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(spacing: 22) {
                                switch model.tab {
                                case .home: HomeViewPS()
                                case .levels: ChaptersViewPS()
                                case .daily: DailyChallengeViewPS()
                                case .collection: CollectionViewPS()
                                }
                                if let error = model.persistence.errorMessage {
                                    GlassCardPS(accent: ColorPS.warning) { Text(error).font(.footnote).foregroundStyle(ColorPS.warning) }
                                }
                                if !model.catalog.errors.isEmpty {
                                    GlassCardPS(accent: ColorPS.warning) { Text("Some level content is unavailable. \(model.catalog.levels.count) verified levels are ready to play.").font(.footnote) }
                                }
                            }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 110)
                        }.scrollIndicators(.hidden)
                            .ignoresSafeArea(.container, edges: .bottom)
                        CustomTabBarPS().padding(.horizontal, 16).padding(.bottom, 8)
                    }
                }
            }
        }
        .foregroundStyle(ColorPS.text).preferredColorScheme(.dark)
        .task { model.systemReduceMotion = reduceMotion; await model.startApp() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                model.now = .now
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.pause(); model.audio.pause() } else { model.refresh() }
        }
        .onChange(of: model.gameCenter.controller != nil) { _, needsPresentation in
            if needsPresentation { model.sheet = nil }
        }
        .onChange(of: model.gameCenter.authenticated) { _, authenticated in
            if authenticated { Task { await model.syncGameCenter() } }
        }
        .onChange(of: model.settings.music) { _, _ in model.applyAudioSettings() }
        .onChange(of: model.settings.sound) { _, _ in model.applyAudioSettings() }
        .onChange(of: model.settings.haptics) { _, enabled in
            model.haptics.prepare(enabled: enabled)
            if enabled { model.interfaceFeedback() }
        }
        .onChange(of: model.settings.reducedEffects) { _, _ in model.applySceneSettings() }
        .onChange(of: model.settings.tutorialTips) { _, _ in model.applyTutorialSettings() }
        .onChange(of: reduceMotion) { _, value in model.systemReduceMotion = value; if model.sessionState != .resolvingMove { model.configureScene() } }
        .sheet(item: $model.sheet) { route in
            SheetContainerPS(route: route).environment(model).preferredColorScheme(.dark)
        }
        .sheet(isPresented: Binding(get: { model.gameCenter.controller != nil && model.sheet == nil && (model.currentLevel == nil || model.sessionState == .paused) }, set: { if !$0 { model.gameCenter.controller = nil } })) {
            if let controller = model.gameCenter.controller { GameCenterSheetPS(controller: controller) { model.gameCenter.controller = nil } }
        }
    }
}

struct CustomTabBarPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTabPS.allCases, id: \.self) { tab in
                let selected = model.tab == tab
                Button {
                    model.interfaceFeedback()
                    withAnimation(model.reduced ? nil : .spring(response: 0.3, dampingFraction: 0.65)) { model.tab = tab }
                } label: {
                    VStack(spacing: 5) {
                        AssetIconPS(name: "tab_\(tab.rawValue.lowercased())", fallback: tab.symbol).frame(width: 26, height: 26)
                            .scaleEffect(selected ? 1.1 : 1)
                        Text(tab.rawValue).font(.system(.caption, design: .rounded, weight: .heavy))
                    }.frame(maxWidth: .infinity).frame(height: 64)
                        .foregroundStyle(selected ? ColorPS.background : ColorPS.secondary)
                        .background {
                            if selected {
                                Capsule().fill(LinearGradient(colors: [Color(hexPS: 0x89F7FF), ColorPS.cyan, ColorPS.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.4)))
                                    .shadow(color: ColorPS.cyan.opacity(0.4), radius: 9, y: 3)
                            }
                        }
                }.buttonStyle(JuicyButtonStylePS()).accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(8)
        .background {
            Capsule().fill(LinearGradient(
                colors: [ColorPS.elevated.opacity(0.98), ColorPS.secondaryBackground.opacity(0.98)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
        .overlay {
            Capsule().strokeBorder(LinearGradient(
                colors: [ColorPS.cyan.opacity(0.65), .white.opacity(0.25), ColorPS.violet.opacity(0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
        .accessibilityIdentifier("floating-tab-bar")
    }
}

struct SheetContainerPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    @Environment(\.dismiss) private var dismiss
    let route: AppSheetPS
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    switch route {
                    case .settings: SettingsViewPS()
                    case .statistics: StatisticsViewPS()
                    case .weekly: WeeklyChallengeViewPS()
                    case .privacy: LegalViewPS(isPrivacy: true)
                    case .terms: LegalViewPS(isPrivacy: false)
                    case .debug:
                        #if DEBUG
                        DebugViewPS()
                        #endif
                    }
                }.padding(24)
            }.background { EnergyBackgroundPS(accent: ColorPS.violet) }.foregroundStyle(ColorPS.text)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(ColorPS.cyan) } }
        }.onDisappear { if model.sessionState == .paused { model.configureScene() } }
    }
}

#Preview { RootViewPS().environment(PulseShiftViewModelPS(preview: true)) }
