//
//  GameScene.swift
//  Spacewar
//
//  Created by Dan Kang on 4/20/15.
//  Copyright (c) 2015 Dan Kang. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {

    let kShipName = "ship"
    let kBulletName = "bullet"
    let motionManager = CMMotionManager()

    var tapQueue: Array<Int> = []

    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        motionManager.startAccelerometerUpdates()
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)

        backgroundColor = SKColor.blackColor()

        let ship = makeShip()
        ship.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        addChild(ship)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */

        if let touch = touches.first as? UITouch {
            let location = touch.locationInView(view)
            if location.x > view?.center.x {
                // Fire bullet
                tapQueue.append(1)
            } else {
                // Propel ship
                if let ship = childNodeWithName(kShipName) {
                    let rotation = Float(ship.zRotation) + Float(M_PI_2)
                    let thrust: CGFloat = 500.0
                    let xv = thrust * CGFloat(cosf(rotation))
                    let yv = thrust * CGFloat(sinf(rotation))
                    let thrustVector = CGVectorMake(xv, yv)
                    ship.physicsBody?.applyForce(thrustVector)
                }
            }
        }

//        for touch in (touches as! Set<UITouch>) {
//            let location = touch.locationInNode(self)
//            
//            let sprite = SKSpriteNode(imageNamed:"Spaceship")
//            
//            sprite.xScale = 0.5
//            sprite.yScale = 0.5
//            sprite.position = location
//            
//            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
//            
//            sprite.runAction(SKAction.repeatActionForever(action))
//            
//            self.addChild(sprite)
//        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        processUserMotionForUpdate(currentTime)
        processUserTapsForUpdate(currentTime)
    }

    func makeShip() -> SKNode {
        let ship = SKSpriteNode(imageNamed:"Spaceship")
        ship.name = kShipName
        ship.xScale = 0.1
        ship.yScale = 0.1

        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        ship.physicsBody!.dynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 1.0

        return ship
    }

    func makeBullet(ship: SKNode) -> SKNode {
        let bullet = SKSpriteNode(color: SKColor.grayColor(), size: CGSizeMake(4, 8))
        bullet.name = kBulletName
        bullet.zRotation = ship.zRotation

        bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
        bullet.physicsBody!.velocity = ship.physicsBody!.velocity
        bullet.physicsBody!.dynamic = false
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.mass = 0.1

        return bullet
    }

    func fireBullet(bullet: SKNode, destination: CGPoint, duration: CFTimeInterval) {
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        bullet.runAction(bulletAction)
        addChild(bullet)
    }

    func fireShipBullets() {
        if let ship = childNodeWithName(kShipName) {
            let bullet = makeBullet(ship)

            let shipDirection = Float(ship.zRotation) + Float(M_PI_2)
            let padding = ship.frame.size.height - bullet.frame.size.height / 2
            let bulletX = ship.position.x + CGFloat(cosf(shipDirection)) * padding
            let bulletY = ship.position.y + CGFloat(sinf(shipDirection)) * padding
            bullet.position = CGPointMake(bulletX, bulletY)

            let destX = ship.position.x + CGFloat(cosf(shipDirection)) * 500
            let destY = ship.position.y + CGFloat(sinf(shipDirection)) * 500
            let bulletDestination = CGPointMake(destX, destY)
            fireBullet(bullet, destination: bulletDestination, duration: 1.0)
        }
    }

    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        for tap in tapQueue {
            fireShipBullets()
            tapQueue.removeAtIndex(0)
        }
    }

    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        let ship = childNodeWithName(kShipName) as! SKSpriteNode
        if let data = motionManager.accelerometerData {
            if fabs(data.acceleration.y) > 0.1 {
                // Rotate ship
                let rotate = SKAction.rotateByAngle(CGFloat(data.acceleration.y * M_PI_2 * -0.1), duration: 0.1)
                ship.runAction(rotate)
            }
        }
    }
}
