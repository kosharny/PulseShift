import SwiftUI

#if DEBUG
struct DebugViewPS: View {
    @Environment(PulseShiftViewModelPS.self) private var model
    var body: some View {
        @Bindable var model = model
        @Bindable var settings = model.settings
        VStack(alignment: .leading, spacing: 20) {
            Text("Developer tools").font(.title.bold())
            Toggle("Unlock all chapters", isOn: $model.unlockAll)
            Toggle("Show FPS", isOn: $model.showFPS)
            Toggle("Grid coordinates, IDs & links", isOn: $model.showDebugLabels)
            Toggle("Reduced particle effects", isOn: $settings.reducedEffects)
            Button("Validate all levels") {
                let errors = model.catalog.levels.flatMap { level in LevelValidatorPS.errors(in: level).map { "\(level.id): \($0)" } }
                model.debugMessage = errors.isEmpty ? "\(model.catalog.levels.count) solutions verified." : errors.joined(separator: "\n")
            }
            Button("Show current solution") { model.debugMessage = model.currentLevel?.solutionMoves.joined(separator: " → ") ?? "Select a level first." }
            Button("Simulate owned themes") { model.persistence.player.unlockedThemes = ThemePS.all.map(\.id); model.persistence.save() }
            Button("Reset progress", role: .destructive) { model.resetConfirmation = "progress" }
            Text(model.debugMessage).font(.footnote).foregroundStyle(ColorPS.cyan)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                ForEach(model.catalog.levels) { level in Button("\(level.id)") { model.start(level) }.buttonStyle(.bordered) }
            }
        }.tint(ColorPS.cyan)
            .confirmationDialog("Reset all progress?", isPresented: Binding(get: { model.resetConfirmation != nil }, set: { if !$0 { model.resetConfirmation = nil } })) {
                Button("Reset progress", role: .destructive) { model.reset("progress") }
            }
    }
}
#endif
