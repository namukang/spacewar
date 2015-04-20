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
    let motionManager = CMMotionManager()

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
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            
            sprite.runAction(SKAction.repeatActionForever(action))
            
            self.addChild(sprite)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        processUserMotionForUpdate(currentTime)
    }

    func makeShip() -> SKNode {
        let ship = SKSpriteNode(imageNamed:"Spaceship")
        ship.name = kShipName
        ship.xScale = 0.1
        ship.yScale = 0.1

        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        ship.physicsBody!.dynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.02

        return ship
    }

    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        let ship = childNodeWithName(kShipName) as! SKSpriteNode
        if let data = motionManager.accelerometerData {
            if fabs(data.acceleration.y) > 0.2 {
                ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.y), 0))
            }
        }
    }
}
