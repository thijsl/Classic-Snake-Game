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
        gameOverLabel.position = CGPoint(x: 0, y: 60)
        gameOverNode.addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "Score: \(currentScore)")
        scoreLabel.fontName = "ArcadeClassic"
        scoreLabel.fontSize = 32
        scoreLabel.position = CGPoint(x: 0, y: 0)
        gameOverNode.addChild(scoreLabel)
        
        let highScoreLabel = SKLabelNode(text: "High Score: \(highScore)")
        highScoreLabel.fontName = "ArcadeClassic"
        highScoreLabel.fontSize = 32
        highScoreLabel.position = CGPoint(x: 0, y: -40)
        gameOverNode.addChild(highScoreLabel)
        
        let messageLabel = SKLabelNode(text: "Tap to try again!")
        messageLabel.fontName = "ArcadeClassic"
        messageLabel.fontSize = 24
        messageLabel.position = CGPoint(x: 0, y: -100)
        gameOverNode.addChild(messageLabel)
        
        gameOverNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverNode)
        
        // Enable touch handling for restart
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only handle touches when game is over
        if action(forKey: "snakeMovement") == nil {
            // Remove game over menu
            children.filter { $0.name == "gameOverMenu" }.forEach { $0.removeFromParent() }
            
            // Reset game
            snake.forEach { $0.removeFromParent() }
            food?.removeFromParent()
            currentScore = 0
            scoreLabel?.text = "Score: 0"
            
            // Restart game
            setupGame()
            startGame()
        }
    }
    
    private func spawnFood() {
        food?.removeFromParent()
        
        // Calculate grid positions within safe area
        let gridWidth = Int(playableWidth / snakeBodySize)
        let gridHeight = Int(playableHeight / snakeBodySize)
        
        // Generate random position within safe area
        var position: CGPoint
        repeat {
            let x = Int.random(in: 0..<gridWidth) * Int(snakeBodySize) + Int(safeAreaInset)
            let y = Int.random(in: 0..<gridHeight) * Int(snakeBodySize) + Int(safeAreaInset)
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
        
        // Improved collision detection with food
        if let food = food {
            let distance = hypot(newPosition.x - food.position.x, newPosition.y - food.position.y)
            if distance < snakeBodySize {
                // Play crunch sound
                if let crunchSound = crunchSound {
                    run(crunchSound)
                }
                
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
