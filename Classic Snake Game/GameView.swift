import SwiftUI
import SpriteKit

struct GameView: View {
    private let directionFeedback = UIImpactFeedbackGenerator(style: .light)
    private let foodFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var scene: SKScene {
        let scene = GameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .aspectFill
        // Pass the feedback generators to the scene
        if let gameScene = scene as? GameScene {
            gameScene.foodFeedback = foodFeedback
        }
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
                            
                            // Prepare haptic feedback
                            directionFeedback.prepare()
                            
                            if horizontalAmount > verticalAmount {
                                // Trigger light haptic for direction change
                                directionFeedback.impactOccurred()
                                NotificationCenter.default.post(
                                    name: .init("ChangeDirection"),
                                    object: translation.width > 0 ? "right" : "left"
                                )
                            } else {
                                // Trigger light haptic for direction change
                                directionFeedback.impactOccurred()
                                NotificationCenter.default.post(
                                    name: .init("ChangeDirection"),
                                    object: translation.height > 0 ? "down" : "up"
                                )
                            }
                        }
                )
        }
    }
} 