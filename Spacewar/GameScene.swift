//
//  GameScene.swift
//  Spacewar
//
//  Created by Dan Kang on 4/20/15.
//  Copyright (c) 2015 Dan Kang. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    let gravityStrength: Float = 0.5
    let thrustStrength: CGFloat = 500.0

    let shipCategory: UInt32 = 0x1 << 0
    let missileCategory: UInt32 = 0x1 << 1
    let starCategory: UInt32 = 0x1 << 2

    let kShipName = "ship"
    let kEnemyName = "enemy"
    let kMissileName = "missile"
    let motionManager = CMMotionManager()

    var resetGame = false
    var scoreLabel: SKLabelNode!
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    var ship: SKNode!
    var enemy: SKNode!

    var propelTimer: NSTimer?

    var tapQueue: Array<Int> = []
    var dots: Array<SKNode> = []

    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        motionManager.startAccelerometerUpdates()
        scaleMode = SKSceneScaleMode.AspectFit
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor.blackColor()

        // Create scoreLabel
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: frame.size.width, y: frame.size.height - 45)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        addChild(scoreLabel)

        let star = makeStar()
        addChild(star)

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let gravityField = SKFieldNode.radialGravityField()
        gravityField.position = center
        gravityField.strength = gravityStrength
        addChild(gravityField)

        newGame()
    }

    func delay(delay: Double, closure: () -> ()) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), closure)
    }


    func newGame() {
        if ship != nil {
            ship.removeFromParent()
        }
        if enemy != nil {
            enemy.removeFromParent()
        }
        if dots.count > 0 {
            removeChildrenInArray(dots)
        }

        // Create stars in background
        dots = []
        for index in 1...50 {
            let randomX = CGFloat(arc4random_uniform(UInt32(frame.size.width)))
            let randomY = CGFloat(arc4random_uniform(UInt32(frame.size.height)))
            let dot = SKSpriteNode(color: SKColor.grayColor(), size: CGSizeMake(2, 2))
            dot.position = CGPoint(x: randomX, y: randomY)
            addChild(dot)
            dots.append(dot)
        }

        // Update score
        if ship != nil && enemy != nil {
            let playerLost = ship.userData!["dead"] as! Bool
            let opponentLost = enemy.userData!["dead"] as! Bool
            if playerLost && opponentLost {
            } else if playerLost {
                score--
            } else if opponentLost {
                score++
            }
        }

        // Create ships
        ship = makeShip(kShipName)
        ship.position = CGPoint(x: size.width * 0.8, y: size.height * 0.2)
        addChild(ship)

        enemy = makeShip(kEnemyName)
        enemy.position = CGPoint(x: size.width * 0.2, y: size.height * 0.8)
        enemy.zRotation = CGFloat(M_PI)
        if let enemy = enemy as? SKSpriteNode {
            enemy.color = SKColor.redColor()
            enemy.colorBlendFactor = 0.5
        }
        addChild(enemy)

        resetGame = false
    }

    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody, secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // firstBody is always a ship
        if secondBody.categoryBitMask & starCategory != 0 {
            let randomX = CGFloat(arc4random_uniform(UInt32(frame.size.width)))
            let randomY = CGFloat(arc4random_uniform(UInt32(frame.size.height)))
            let randomPoint = CGPoint(x: randomX, y: randomY)
            firstBody.node!.runAction(SKAction.moveTo(randomPoint, duration: 0))
            return
        }

        firstBody.node!.userData!["dead"] = true
        let explosionAction = SKAction.sequence([SKAction.removeFromParent()])
        firstBody.node!.runAction(explosionAction)

        let shipsCollided = secondBody.categoryBitMask & shipCategory != 0
        if shipsCollided {
            secondBody.node!.userData!["dead"] = true
            secondBody.node!.runAction(explosionAction)
            delay(3.0) {
                self.resetGame = true
            }
        }

        if secondBody.categoryBitMask & missileCategory != 0 {
            secondBody.node!.removeFromParent()
        }

        // Avoid resetting the game twice when one player dies then other player dies
        let shipDead = ship.userData!["dead"] as! Bool
        let enemyDead = enemy.userData!["dead"] as! Bool
        if shipsCollided || !(shipDead && enemyDead) {
            delay(3.0) {
                self.resetGame = true
            }
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */

        let playerDead = ship.userData!["dead"] as! Bool
        if playerDead {
            return
        }

        if let touch = touches.first as? UITouch {
            let location = touch.locationInView(view)
            if location.x > view?.center.x {
                // Fire missile
                tapQueue.append(1)
            } else {
                // Propel ship
                propelTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "propelShip", userInfo: nil, repeats: true)
                ship.runAction(SKAction.colorizeWithColor(UIColor.greenColor(), colorBlendFactor: 0.5, duration: 0.1))
            }
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            let location = touch.locationInView(view)
            if location.x < view?.center.x {
                // Stop propelling ship
                propelTimer?.invalidate()
                ship.runAction(SKAction.colorizeWithColor(UIColor.greenColor(), colorBlendFactor: 0.0, duration: 0.1))
            }
        }
    }

    func propelShip() {
        let rotation = Float(ship.zRotation) + Float(M_PI_2)
        let thrust: CGFloat = thrustStrength
        let xv = thrust * CGFloat(cosf(rotation))
        let yv = thrust * CGFloat(sinf(rotation))
        let thrustVector = CGVectorMake(xv, yv)
        ship.physicsBody?.applyForce(thrustVector)
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if resetGame {
            newGame()
        }
        processUserMotionForUpdate(currentTime)
        processUserTapsForUpdate(currentTime)
        moveEnemy()
        updateLocations()
    }

    func updateLocations() {
        for node in children as! [SKNode] {
            if node.name == kShipName || node.name == kEnemyName || node.name == kMissileName {
                let width = frame.size.width
                let height = frame.size.height
                node.position.x = (node.position.x + width) % width
                node.position.y = (node.position.y + height) % height
            }
        }
    }

    func moveEnemy() {
        let dead = enemy.userData!["dead"] as! Bool
        if dead {
            return
        }

        // Turn randomly
        var rand = Double(arc4random()) / Double(UINT32_MAX)
        if arc4random_uniform(2) == 0 {
            rand = -1 * rand
        }
        let rotate = SKAction.rotateByAngle(CGFloat(rand * M_PI_2 * -0.2), duration: 0.1)
        enemy.runAction(rotate)

        // Thrust randomly
        let rotation = Float(enemy.zRotation) + Float(M_PI_2)
        let thrust: CGFloat = thrustStrength
        let xv = thrust * CGFloat(cosf(rotation))
        let yv = thrust * CGFloat(sinf(rotation))
        let thrustVector = CGVectorMake(xv, yv)
        if arc4random_uniform(10) == 0 {
            enemy.physicsBody?.applyForce(thrustVector)
        }

        // Fire missile randomly
        let playerDead = ship.userData!["dead"] as! Bool
        if arc4random_uniform(50) == 0 && !playerDead {
            fireMissile(enemy)
        }
    }

    func makeStar() -> SKNode {
        let star = SKSpriteNode(color: SKColor.whiteColor(), size: CGSizeMake(5, 5))
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        star.position = center

        star.physicsBody = SKPhysicsBody(circleOfRadius: 0.1)
        star.physicsBody!.dynamic = false
        star.physicsBody!.categoryBitMask = starCategory

        return star
    }

    func makeShip(name: String) -> SKNode {
        let ship = SKSpriteNode(imageNamed:"Spaceship")
        ship.userData = ["dead": false]
        ship.name = name
        ship.xScale = 0.1
        ship.yScale = 0.1

        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        ship.physicsBody!.mass = 1.0
        ship.physicsBody!.categoryBitMask = shipCategory
        ship.physicsBody!.contactTestBitMask = shipCategory | missileCategory | starCategory

        return ship
    }

    func makeMissile(ship: SKNode) -> SKNode {
        let missile = SKSpriteNode(color: SKColor.grayColor(), size: CGSizeMake(4, 8))
        missile.name = kMissileName
        missile.zRotation = ship.zRotation

        missile.physicsBody = SKPhysicsBody(rectangleOfSize: missile.frame.size)
        missile.physicsBody!.velocity = ship.physicsBody!.velocity
        missile.physicsBody!.mass = 0.1
        missile.physicsBody!.categoryBitMask = missileCategory
        missile.physicsBody!.collisionBitMask = 0x0
        missile.physicsBody!.fieldBitMask = 0x0

        return missile
    }

    func fireMissile(ship: SKNode) {
        let missile = makeMissile(ship)

        let shipDirection = Float(ship.zRotation) + Float(M_PI_2)
        let padding = ship.frame.size.height - missile.frame.size.height / 2
        let missileX = ship.position.x + CGFloat(cosf(shipDirection)) * padding
        let missileY = ship.position.y + CGFloat(sinf(shipDirection)) * padding
        missile.position = CGPointMake(missileX, missileY)

        addChild(missile)

        let impulse: CGFloat = 40.0
        let dx = CGFloat(cosf(shipDirection)) * impulse
        let dy = CGFloat(sinf(shipDirection)) * impulse
        let impulseVector = CGVectorMake(dx, dy)
        missile.physicsBody!.applyImpulse(impulseVector)

        let missileAction = SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.removeFromParent()])
        missile.runAction(missileAction)

    }

    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        for tap in tapQueue {
            fireMissile(ship)
            tapQueue.removeAtIndex(0)
        }
    }

    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        if let data = motionManager.accelerometerData {
            if fabs(data.acceleration.y) > 0.1 {
                var strength = data.acceleration.y
                let maxStrength = 0.5
                if strength > maxStrength {
                    strength = maxStrength
                } else if strength < -1 * maxStrength {
                    strength = -1 * maxStrength
                }
                // Rotate ship
                let rotate = SKAction.rotateByAngle(CGFloat(strength * M_PI_2 * -0.1), duration: 0.1)
                ship.runAction(rotate)
            }
        }
    }
}
