import Foundation
import Observation

@MainActor @Observable final class SettingsPS {
    private let defaults: UserDefaults
    var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
    var music: Bool { didSet { defaults.set(music, forKey: "music") } }
    var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
    var reducedEffects: Bool { didSet { defaults.set(reducedEffects, forKey: "reducedEffects") } }
    var tutorialTips: Bool { didSet { defaults.set(tutorialTips, forKey: "tutorialTips") } }
    var themeID: String { didSet { defaults.set(themeID, forKey: "themeID") } }
    var launched: Bool { didSet { defaults.set(launched, forKey: "launched") } }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sound = defaults.object(forKey: "sound") as? Bool ?? true
        music = defaults.object(forKey: "music") as? Bool ?? true
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
        reducedEffects = defaults.bool(forKey: "reducedEffects")
        tutorialTips = defaults.object(forKey: "tutorialTips") as? Bool ?? true
        themeID = defaults.string(forKey: "themeID") ?? "dark"
        launched = defaults.bool(forKey: "launched")
    }
}
