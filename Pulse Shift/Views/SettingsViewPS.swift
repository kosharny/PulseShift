import SwiftUI

struct SettingsViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        @Bindable var settings = model.settings
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings").font(.system(.largeTitle, design: .rounded, weight: .bold))
            SectionTitlePS(title: "GAMEPLAY")
            GlassCardPS {
                VStack(spacing: 20) {
                    Toggle("Haptics", isOn: $settings.haptics)
                    Toggle("Sound", isOn: $settings.sound)
                    Toggle("Music", isOn: $settings.music)
                    Toggle("Reduced Effects", isOn: $settings.reducedEffects)
                    Toggle("Tutorial Tips", isOn: $settings.tutorialTips)
                }.tint(ColorPS.cyan)
            }
            SectionTitlePS(title: "GAME CENTER")
            GlassCardPS {
                VStack(alignment: .leading, spacing: 14) {
                    Label(model.gameCenter.status, systemImage: model.gameCenter.authenticated ? "checkmark.circle" : "gamecontroller").font(.subheadline).foregroundStyle(ColorPS.secondary)
                    Button("Open Game Center") { model.openGameCenter() }.tint(ColorPS.cyan)
                }
            }
            SectionTitlePS(title: "DATA")
            GlassCardPS {
                VStack(alignment: .leading, spacing: 20) {
                    Button("Reset progress", role: .destructive) { model.resetConfirmation = "progress" }
                    Button("Reset statistics", role: .destructive) { model.resetConfirmation = "statistics" }
                }.tint(ColorPS.danger)
            }
            SectionTitlePS(title: "ABOUT")
            GlassCardPS {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { Text("PULSE SHIFT").font(.headline).tracking(2); Spacer(); Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0").foregroundStyle(ColorPS.secondary) }
                    NavigationLink("Privacy") { ScrollView { LegalViewPS(isPrivacy: true).padding(24) }.background { EnergyBackgroundPS() } }
                    NavigationLink("Terms") { ScrollView { LegalViewPS(isPrivacy: false).padding(24) }.background { EnergyBackgroundPS() } }
                    #if DEBUG
                    Button("Developer tools") { model.sheet = .debug }
                    #endif
                }.tint(ColorPS.cyan)
            }
        }.confirmationDialog("Reset \(model.resetConfirmation ?? "data")?", isPresented: Binding(get: { model.resetConfirmation != nil }, set: { if !$0 { model.resetConfirmation = nil } }), titleVisibility: .visible) {
            Button("Reset \(model.resetConfirmation ?? "data")", role: .destructive) { if let kind = model.resetConfirmation { model.reset(kind) } }.accessibilityIdentifier("confirm-reset")
            Button("Cancel", role: .cancel) { model.resetConfirmation = nil }
        } message: { Text("This permanently deletes local \(model.resetConfirmation ?? "data").") }
    }
}

