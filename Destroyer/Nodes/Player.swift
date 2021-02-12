//
//  Player.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-09.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import Foundation
import SceneKit

enum PlayerAnimationType {
    case walk, attack1, dead
}

class Player: SCNNode {
    
    private var daeHolderNode = SCNNode()
    private var characterNode: SCNNode!
    private var collider:SCNNode!
    
    //animations
    private var walkAnimation = CAAnimation()
    private var attack1Animation = CAAnimation()
    private var deadAnimation = CAAnimation()
    
    //movement
    private var previousUpdateTime = TimeInterval(0.0)
    private var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                
                if isWalking {
                    characterNode.addAnimation(walkAnimation, forKey: "walk")
                } else {
                    characterNode.removeAnimation(forKey: "walk", blendOutDuration: 0.2)
                }
            }
        }
    }
    
    private var directionAngle: Float = 0.0 {
        didSet {
            if directionAngle != oldValue {
                runAction(SCNAction.rotateTo(x: 0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.1, usesShortestUnitArc: true))
            }
        }
    }
    
    
    override init() {
        super.init()
        
        setupModel()
        loadAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init has not been implemented")
    }
    
    //scene
    private func setupModel(){
        
        let playerURL = Bundle.main.url(forResource: "art.scnassets/Scenes/Hero/idle", withExtension: "dae")
        
        let playerScene = try! SCNScene(url: playerURL!, options: nil)
        
        for child in playerScene.rootNode.childNodes {
            daeHolderNode.addChildNode(child)
        }
        
        addChildNode(daeHolderNode)
        
        characterNode = daeHolderNode.childNode(withName: "Bip01", recursively: true)!
        
    }
    
    //animations
    private func loadAnimations(){
        loadAnimation(animationType: .walk, scene: "art.scnassets/Scenes/Hero/walk", identifier: "WalkID")
        loadAnimation(animationType: .attack1, scene: "art.scnassets/Scenes/Hero/attack", identifier: "attackID")
        loadAnimation(animationType: .dead, scene: "art.scnassets/Scenes/Hero/die", identifier: "DeathID")
        
    }
    
    private func loadAnimation(animationType: PlayerAnimationType, scene: String, identifier: String){
        
        let sceneURL = Bundle.main.url(forResource: scene, withExtension: "dae")!
        
        let sceneSource = SCNSceneSource(url: sceneURL, options: nil)!
        
        let animationObj: CAAnimation = sceneSource.entryWithIdentifier(identifier, withClass: CAAnimation.self)!
        
        animationObj.delegate = self
        animationObj.fadeInDuration = 0.2
        animationObj.fadeOutDuration = 0.2
        animationObj.usesSceneTimeBase = false
        animationObj.repeatCount = 0
        
        switch animationType {
        case .walk:
            animationObj.repeatCount = Float.greatestFiniteMagnitude
            walkAnimation = animationObj
        case .attack1:
            animationObj.setValue("attack1", forKey: "animationId")
            attack1Animation = animationObj
        case .dead:
            animationObj.isRemovedOnCompletion = false
            deadAnimation = animationObj
        }
        
        
    }
    
    //movement
    func walkInDirection(_ direction: float3, time: TimeInterval, scene: SCNScene){
        
        if previousUpdateTime == 0.0 {
            return
        }
        
        let deltaTime = Float(min(time-previousUpdateTime, 1/60))
        
        let speed = deltaTime * 1.3
        previousUpdateTime = time
        
        let initialPosition = position
        
        if direction.x != 0.0 && direction.z != 0.0 {
            
            let pos = float3(position)
            position = SCNVector3(pos + direction * speed)
            
            directionAngle = SCNFloat(atan2f(direction.x, direction.z))
            isWalking = true
        } else {
            isWalking = false
        }
        
        //update altitude
        var pos = position
        var endpoint0 = pos
        var endpoint1 = pos
        
        endpoint0.y -= 0.1
        endpoint1.y += 0.88
        
        let results = scene.physicsWorld.rayTestWithSegment(from: endpoint0, to: endpoint1, options: [.collisionBitMask: BitmaskWall, .searchMode: SCNPhysicsWorld.TestSearchMode.closest])
        
        if let result = results.first {
            let groundAltitude = result.worldCoordinates.y
            
            pos.y = groundAltitude
            position = pos
        } else {
            position = initialPosition
        }
    }
    
    //collisions
    var replacementPosition: SCNVector3 = SCNVector3Zero
    
    func setupColliders(with scale:CGFloat){
        
        let geometry = SCNCapsule(capRadius: 45, height: 165)
        
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        
        collider = SCNNode(geometry: geometry)
        
        collider.position = SCNVector3Make(0.0, 140.0, 0.0)
        collider.name = "collider"
        collider.opacity = 0.0
        
        let physicsGeometry = SCNCapsule(capRadius: 47*scale, height: 165*scale)
        let physicsShape = SCNPhysicsShape(geometry: physicsGeometry, options: nil)
        
        collider.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
        collider.physicsBody!.categoryBitMask = BitmaskPlayer
        collider.physicsBody!.contactTestBitMask = BitmaskWall
        
        addChildNode(collider)
    }
    
}

extension Player: CAAnimationDelegate {
    
}
