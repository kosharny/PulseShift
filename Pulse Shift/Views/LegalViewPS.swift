import SwiftUI

struct LegalViewPS: View {
    let isPrivacy: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: isPrivacy ? "hand.raised" : "doc.text").font(.largeTitle).foregroundStyle(ColorPS.cyan)
            Text(isPrivacy ? "Your privacy." : "Terms of use.").font(.system(.largeTitle, design: .rounded, weight: .bold))
            GlassCardPS {
                VStack(alignment: .leading, spacing: 18) {
                    Text(isPrivacy ? "Your puzzles stay on your iPhone." : "PULSE SHIFT").font(.title3.bold())
                    Text(isPrivacy ? "Progress, statistics, daily results and preferences are saved locally. This edition includes no advertising or analytics SDK, and does not send gameplay analytics to a server." : "PULSE SHIFT includes 60 campaign puzzles, daily challenges and a weekly circuit. All puzzles are included. Themes unlock with energy earned by playing. Progress and preferences are stored on this device.")
                    Text(isPrivacy ? "Optional Game Center features use your Apple Game Center account. You can play offline without signing in." : "Themes change presentation only. Play at your own pace, with no lives or timers that limit play.")
                    Text(isPrivacy ? "Reset Progress removes local results and cosmetic progression. Reset Statistics clears the counters while keeping your completed levels." : "Deleting the app can remove local progress. Reset actions cannot be undone. Use of the app is subject to Apple’s Standard License Agreement.")
                    if !isPrivacy, let licenseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        Link("Apple Standard License Agreement", destination: licenseURL)
                            .tint(ColorPS.cyan)
                    }
                }.font(.body).foregroundStyle(ColorPS.secondary)
            }
        }
    }
}

