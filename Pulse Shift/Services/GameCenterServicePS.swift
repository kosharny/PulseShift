import GameKit
import Observation
import SwiftUI

@MainActor @Observable final class GameCenterServicePS {
    var authenticated = false
    var status = "Offline play available"
    var controller: UIViewController?
    private var dashboardRequested = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor [weak self] in
                self?.authenticated = GKLocalPlayer.local.isAuthenticated
                if let controller { self?.controller = controller }
                else if GKLocalPlayer.local.isAuthenticated, self?.dashboardRequested == true {
                    self?.controller = GKGameCenterViewController(state: .dashboard)
                } else { self?.controller = nil }
                if GKLocalPlayer.local.isAuthenticated || error != nil { self?.dashboardRequested = false }
                self?.status = GKLocalPlayer.local.isAuthenticated ? "Connected as \(GKLocalPlayer.local.displayName)" : (error == nil ? "Not signed in" : "Game Center unavailable")
            }
        }
    }
    func open() {
        guard authenticated else { dashboardRequested = true; authenticate(); return }
        controller = GKGameCenterViewController(state: .dashboard)
    }
    func report(achievementIDs: [String], perfectClears: Int) async {
        guard authenticated else { return }
        let achievements = achievementIDs.map { id in
            let achievement = GKAchievement(identifier: "com.pulseshift.\(id)")
            achievement.percentComplete = 100; achievement.showsCompletionBanner = true
            return achievement
        }
        do {
            if !achievements.isEmpty { try await GKAchievement.report(achievements) }
            try await GKLeaderboard.submitScore(perfectClears, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["com.pulseshift.perfectclears"])
            status = "Connected as \(GKLocalPlayer.local.displayName)"
        } catch { status = "Score sync failed. Reopen Game Center to retry." }
    }
}

struct GameCenterSheetPS: UIViewControllerRepresentable {
    let controller: UIViewController
    var dismiss: () -> Void
    func makeCoordinator() -> CoordinatorPS { CoordinatorPS(dismiss: dismiss) }
    func makeUIViewController(context: Context) -> UIViewController {
        (controller as? GKGameCenterViewController)?.gameCenterDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    final class CoordinatorPS: NSObject, GKGameCenterControllerDelegate {
        var dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) { dismiss() }
    }
}
