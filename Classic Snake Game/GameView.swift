import SwiftUI
import SpriteKit
import GameKit

struct GameView: View {
    @StateObject var gameCenter = GameCenterManager()
    
    var scene: SKScene {
        let scene = GameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { gesture in
                            let translation = gesture.translation
                            let horizontalAmount = abs(translation.width)
                            let verticalAmount = abs(translation.height)
                            
                            if horizontalAmount > verticalAmount {
                                NotificationCenter.default.post(
                                    name: .init("ChangeDirection"),
                                    object: translation.width > 0 ? "right" : "left"
                                )
                            } else {
                                NotificationCenter.default.post(
                                    name: .init("ChangeDirection"),
                                    object: translation.height > 0 ? "down" : "up"
                                )
                            }
                        }
                )
        }
        .onAppear {
            gameCenter.authenticatePlayer()
        }
    }
} 