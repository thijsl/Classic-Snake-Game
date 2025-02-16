import SpriteKit
import SwiftUI
import GameKit

class GameScene: SKScene {
    // Game state
    private var snake: [SKShapeNode] = []
    private var food: SKShapeNode?
    private var currentDirection = CGVector(dx: 1, dy: 0)
    private var nextDirection = CGVector(dx: 1, dy: 0)
    
    // Audio
    private var crunchSound: SKAction?
    
    // Scoring
    private var currentScore = 0
    private var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "HighScore") }
        set { UserDefaults.standard.set(newValue, forKey: "HighScore") }
    }
    
    // UI elements
    private var scoreLabel: SKLabelNode?
    private var highScoreLabel: SKLabelNode?
    
    // Game constants
    private let gridSize = 20
    private let snakeSpeed = 0.1 // seconds per move
    private let snakeBodySize: CGFloat = 18.0 // Slightly smaller to ensure visibility
    private let safeAreaInset: CGFloat = 20.0 // Reduced from 40.0
    
    // Computed properties for game boundaries
    private var playableWidth: CGFloat { frame.width - (2 * safeAreaInset) }
    private var playableHeight: CGFloat { frame.height - (2 * safeAreaInset) }
    private var playableRect: CGRect {
        CGRect(x: safeAreaInset, 
               y: safeAreaInset, 
               width: playableWidth, 
               height: playableHeight)
    }
    
    // Add property for feedback
    var foodFeedback: UIImpactFeedbackGenerator?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Load sound
        if let soundURL = Bundle.main.url(forResource: "crunch", withExtension: "wav") {
            crunchSound = SKAction.playSoundFileNamed(soundURL.lastPathComponent, waitForCompletion: false)
        }
        
        setupGame()
        setupScoreLabels()
        startGame()
        
        // Add observer for direction changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDirectionChange(_:)),
            name: .init("ChangeDirection"),
            object: nil
        )
    }
    
    private func setupGame() {
        // Initialize snake
        let head = SKShapeNode(rectOf: CGSize(width: snakeBodySize, height: snakeBodySize))
        head.fillColor = .systemBlue
        head.strokeColor = .clear
        head.position = CGPoint(x: playableRect.midX, y: playableRect.midY)
        addChild(head)
        snake = [head]
        
        // Add food
        spawnFood()
    }
    
    private func setupScoreLabels() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel?.fontName = "ArcadeClassic"
        scoreLabel?.fontSize = 24
        // Position at bottom left
        scoreLabel?.position = CGPoint(x: safeAreaInset + 60, y: safeAreaInset)
        scoreLabel?.horizontalAlignmentMode = .left
        addChild(scoreLabel!)
        
        highScoreLabel = SKLabelNode(text: "High: \(highScore)")
        highScoreLabel?.fontName = "ArcadeClassic"
        highScoreLabel?.fontSize = 24
        // Position at bottom right
        highScoreLabel?.position = CGPoint(x: frame.width - safeAreaInset - 60, y: safeAreaInset)
        highScoreLabel?.horizontalAlignmentMode = .right
        addChild(highScoreLabel!)
    }
    
    private func startGame() {
        let moveAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in self?.moveSnake() },
                SKAction.wait(forDuration: snakeSpeed)
            ])
        )
        run(moveAction, withKey: "snakeMovement")
    }
    
    private func gameOver() {
        removeAction(forKey: "snakeMovement")
        
        // Update high score if needed
        if currentScore > highScore {
            highScore = currentScore
        }
        
        // Submit score to Game Center
        if let gameCenter = (scene?.view?.window?.rootViewController as? UIHostingController<GameView>)?.rootView.gameCenter {
            gameCenter.submitScore(currentScore)
        }
        
        // Show game over menu
        let gameOverNode = SKNode()
        gameOverNode.name = "gameOverMenu"
        
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "ArcadeClassic"
        gameOverLabel.fontSize = 48
        gameOverLabel.position = CGPoint(x: 0, y: 80)
        gameOverNode.addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "Score: \(currentScore)")
        scoreLabel.fontName = "ArcadeClassic"
        scoreLabel.fontSize = 32
        scoreLabel.position = CGPoint(x: 0, y: 20)
        gameOverNode.addChild(scoreLabel)
        
        let highScoreLabel = SKLabelNode(text: "High Score: \(highScore)")
        highScoreLabel.fontName = "ArcadeClassic"
        highScoreLabel.fontSize = 32
        highScoreLabel.position = CGPoint(x: 0, y: -20)
        gameOverNode.addChild(highScoreLabel)
        
        // Add share button
        let shareButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
        shareButton.fillColor = .systemBlue
        shareButton.strokeColor = .clear
        shareButton.position = CGPoint(x: -70, y: -80)
        shareButton.name = "shareButton"
        
        let shareLabel = SKLabelNode(text: "Share")
        shareLabel.fontName = "ArcadeClassic"
        shareLabel.fontSize = 24
        shareLabel.verticalAlignmentMode = .center
        shareLabel.position = CGPoint(x: 0, y: 0)
        shareButton.addChild(shareLabel)
        gameOverNode.addChild(shareButton)
        
        // Add new game button
        let newGameButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
        newGameButton.fillColor = .systemGreen
        newGameButton.strokeColor = .clear
        newGameButton.position = CGPoint(x: 70, y: -80)
        newGameButton.name = "newGameButton"
        
        let newGameLabel = SKLabelNode(text: "New Game")
        newGameLabel.fontName = "ArcadeClassic"
        newGameLabel.fontSize = 24
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.position = CGPoint(x: 0, y: 0)
        newGameButton.addChild(newGameLabel)
        gameOverNode.addChild(newGameButton)
        
        gameOverNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverNode)
        
        // Enable touch handling for buttons
        isUserInteractionEnabled = true
    }
    
    private func resetGame() {
        // Remove all game over menu nodes
        childNode(withName: "gameOverMenu")?.removeFromParent()
        
        // Clean up game elements
        snake.forEach { $0.removeFromParent() }
        food?.removeFromParent()
        
        // Reset score
        currentScore = 0
        scoreLabel?.text = "Score: 0"
        highScoreLabel?.text = "High: \(highScore)"
        
        // Start new game
        setupGame()
        startGame()
    }
    
    private func shareScore() {
        let shareText = "🐍 I scored \(currentScore) points in Classic Snake Game! #ClassicSnakeGame"
        
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(
                activityItems: [shareText],
                applicationActivities: nil
            )
            
            // Configure for iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = viewController.view
                
                // Get the share button's position in the window coordinate space
                if let gameOverMenu = self.childNode(withName: "gameOverMenu"),
                   let shareButton = gameOverMenu.childNode(withName: "shareButton") {
                    let buttonPosition = shareButton.convert(CGPoint.zero, to: self)
                    let scenePosition = self.view?.convert(buttonPosition, to: viewController.view) ?? .zero
                    
                    popoverController.sourceRect = CGRect(
                        origin: scenePosition,
                        size: CGSize(width: 120, height: 40)
                    )
                } else {
                    // Fallback to center if button not found
                    popoverController.sourceRect = viewController.view.bounds
                }
                popoverController.permittedArrowDirections = [.any]
            }
            
            viewController.present(activityViewController, animated: true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if game is over and menu exists
        if let gameOverMenu = childNode(withName: "gameOverMenu") {
            let menuLocation = gameOverMenu.convert(location, from: self)
            
            // Check for share button tap
            if let shareButton = gameOverMenu.childNode(withName: "shareButton") as? SKShapeNode,
               shareButton.contains(menuLocation) {
                shareScore()
                return
            }
            
            // Check for new game button tap
            if let newGameButton = gameOverMenu.childNode(withName: "newGameButton") as? SKShapeNode,
               newGameButton.contains(menuLocation) {
                resetGame()
            }
        }
    }
    
    private func spawnFood() {
        food?.removeFromParent()
        
        // Calculate grid positions within safe area
        let gridWidth = Int((playableWidth) / snakeBodySize)
        let gridHeight = Int((playableHeight) / snakeBodySize)
        
        // Generate random position within safe area
        var position: CGPoint
        repeat {
            // Calculate grid-aligned positions
            let x = CGFloat(Int.random(in: 0..<gridWidth)) * snakeBodySize + safeAreaInset
            let y = CGFloat(Int.random(in: 0..<gridHeight)) * snakeBodySize + safeAreaInset
            position = CGPoint(x: x, y: y)
        } while snake.contains(where: { 
            abs($0.position.x - position.x) < snakeBodySize/2 && 
            abs($0.position.y - position.y) < snakeBodySize/2 
        })
        
        food = SKShapeNode(rectOf: CGSize(width: snakeBodySize, height: snakeBodySize))
        food?.fillColor = .orange
        food?.strokeColor = .clear
        food?.position = position
        addChild(food!)
    }
    
    private func moveSnake() {
        currentDirection = nextDirection
        
        let head = snake.first!
        
        // Calculate new position with grid alignment
        var newPosition = CGPoint(
            x: head.position.x + currentDirection.dx * snakeBodySize,
            y: head.position.y + currentDirection.dy * snakeBodySize
        )
        
        // Wrap around screen within safe area
        if newPosition.x < safeAreaInset {
            newPosition.x = playableRect.maxX - snakeBodySize
        } else if newPosition.x > playableRect.maxX - snakeBodySize {
            newPosition.x = safeAreaInset
        }
        
        if newPosition.y < safeAreaInset {
            newPosition.y = playableRect.maxY - snakeBodySize
        } else if newPosition.y > playableRect.maxY - snakeBodySize {
            newPosition.y = safeAreaInset
        }
        
        // Ensure grid alignment after wrapping
        newPosition = CGPoint(
            x: round((newPosition.x - safeAreaInset) / snakeBodySize) * snakeBodySize + safeAreaInset,
            y: round((newPosition.y - safeAreaInset) / snakeBodySize) * snakeBodySize + safeAreaInset
        )
        
        // Improved collision detection with food
        if let food = food {
            let distance = hypot(newPosition.x - food.position.x, newPosition.y - food.position.y)
            if distance < snakeBodySize {
                // Play crunch sound
                if let crunchSound = crunchSound {
                    run(crunchSound)
                }
                
                // Trigger medium haptic for food collection
                foodFeedback?.prepare()
                foodFeedback?.impactOccurred()
                
                currentScore += 1
                scoreLabel?.text = "Score: \(currentScore)"
                spawnFood()
                // Don't remove the tail when food is eaten
            } else {
                snake.last?.removeFromParent()
                snake.removeLast()
            }
        }
        
        if checkCollision(at: newPosition) {
            gameOver()
            return
        }
        
        let newHead = SKShapeNode(rectOf: CGSize(width: snakeBodySize, height: snakeBodySize))
        newHead.fillColor = .systemBlue
        newHead.strokeColor = .clear
        newHead.position = newPosition
        addChild(newHead)
        snake.insert(newHead, at: 0)
    }
    
    private func checkCollision(at position: CGPoint) -> Bool {
        // Only check for self collision now, walls are handled by wrapping
        return snake.contains(where: { 
            abs($0.position.x - position.x) < snakeBodySize/2 && 
            abs($0.position.y - position.y) < snakeBodySize/2 
        })
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Update score labels position when screen size changes
        scoreLabel?.position = CGPoint(x: safeAreaInset + 60, y: safeAreaInset)
        highScoreLabel?.position = CGPoint(x: frame.width - safeAreaInset - 60, y: safeAreaInset)
    }
    
    @objc private func handleDirectionChange(_ notification: Notification) {
        guard let direction = notification.object as? String else { return }
        
        // Prevent 180-degree turns
        switch direction {
        case "up" where currentDirection.dy != -1:
            nextDirection = CGVector(dx: 0, dy: 1)
        case "down" where currentDirection.dy != 1:
            nextDirection = CGVector(dx: 0, dy: -1)
        case "left" where currentDirection.dx != 1:
            nextDirection = CGVector(dx: -1, dy: 0)
        case "right" where currentDirection.dx != -1:
            nextDirection = CGVector(dx: 1, dy: 0)
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
