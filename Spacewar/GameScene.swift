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

    let shipCategory: UInt32 = 0x1 << 0
    let missileCategory: UInt32 = 0x1 << 1
    let starCategory: UInt32 = 0x1 << 2
    let edgeCategory: UInt32 = 0x1 << 3

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

    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        motionManager.startAccelerometerUpdates()
        scaleMode = SKSceneScaleMode.AspectFit
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.categoryBitMask = edgeCategory
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

        let star = makeStar()
        addChild(star)

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let gravityField = SKFieldNode.radialGravityField()
        gravityField.position = center
        gravityField.strength = 0.5
        addChild(gravityField)
    }

    func delay(delay: Double, closure: () -> ()) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), closure)
    }


    func newGame() {
        ship.removeFromParent()
        enemy.removeFromParent()

        let playerLost = ship.userData!["dead"] as! Bool
        let opponentLost = enemy.userData!["dead"] as! Bool
        if playerLost && opponentLost {
        } else if playerLost {
            score--
        } else {
            score++
        }

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
            }
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            let location = touch.locationInView(view)
            if location.x < view?.center.x {
                // Stop propelling ship
                propelTimer?.invalidate()
            }
        }
    }

    func propelShip() {
        let rotation = Float(ship.zRotation) + Float(M_PI_2)
        let thrust: CGFloat = 500.0
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
    }

    func makeStar() -> SKNode {
        let star = SKSpriteNode(color: SKColor.whiteColor(), size: CGSizeMake(5, 5))
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        star.position = center

        star.physicsBody = SKPhysicsBody(circleOfRadius: 1)
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
        ship.physicsBody!.collisionBitMask = edgeCategory

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

        return missile
    }

    func fireMissile(missile: SKNode, destination: CGPoint, duration: CFTimeInterval) {
        let missileAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        missile.runAction(missileAction)
        addChild(missile)
    }

    func fireShipMissiles() {
        let missile = makeMissile(ship)

        let shipDirection = Float(ship.zRotation) + Float(M_PI_2)
        let padding = ship.frame.size.height - missile.frame.size.height / 2
        let missileX = ship.position.x + CGFloat(cosf(shipDirection)) * padding
        let missileY = ship.position.y + CGFloat(sinf(shipDirection)) * padding
        missile.position = CGPointMake(missileX, missileY)

        let destX = ship.position.x + CGFloat(cosf(shipDirection)) * 500
        let destY = ship.position.y + CGFloat(sinf(shipDirection)) * 500
        let missileDestination = CGPointMake(destX, destY)
        fireMissile(missile, destination: missileDestination, duration: 1.0)
    }

    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        for tap in tapQueue {
            fireShipMissiles()
            tapQueue.removeAtIndex(0)
        }
    }

    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        if let data = motionManager.accelerometerData {
            if fabs(data.acceleration.y) > 0.1 {
                // Rotate ship
                let rotate = SKAction.rotateByAngle(CGFloat(data.acceleration.y * M_PI_2 * -0.1), duration: 0.1)
                ship.runAction(rotate)
            }
        }
    }
}
