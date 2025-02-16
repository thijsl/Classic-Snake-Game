import GameKit

class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    @Published var isAuthenticated = false
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                // Present authentication view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.first?.rootViewController?.present(viewController, animated: true)
                }
            } else if let error = error {
                print("Game Center authentication error: \(error.localizedDescription)")
            } else {
                self?.isAuthenticated = true
                self?.loadLeaderboard()
            }
        }
    }
    
    func submitScore(_ score: Int) {
        if isAuthenticated {
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                leaderboardIDs: ["classic_snake_leaderboard"]) { error in
                if let error = error {
                    print("Error submitting score: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadLeaderboard() {
        // Load leaderboard configuration
        GKLeaderboard.loadLeaderboards(IDs: ["classic_snake_leaderboard"]) { [weak self] leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
} 