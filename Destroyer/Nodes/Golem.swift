//
//  Golem.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-12.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import Foundation
import SceneKit


enum GolemAnimationType {
    case walk, attack1, dead
}

class Golem:SCNNode {
    
    var gameView: GameView!
    
    
    private let daeHolderNoder = SCNNode()
    private var characterNode: SCNNode!
    private var enemy: Player!
    
    private var walkAnimation = CAAnimation()
    private var deadAnimation = CAAnimation()
    private var attack1Animation = CAAnimation()
    
    //movement
    private var previousUpdateTime = TimeInterval(0.0)
    private var noticeDistance:Float = 1.4
    private var moveSpeedLimiter = Float(0.5)
    
    //collision
    private var collider: SCNNode!
    
    private var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                if isWalking {
                    addAnimation(walkAnimation, forKey: "walk")
                } else {
                    removeAnimation(forKey: "walk")
                }
            }
        }
    }
    
    var isCollideWithEnemy = false {
        
        didSet {
            if oldValue != isCollideWithEnemy {
                if isCollideWithEnemy {
                    isWalking = false
                }
            }
        }
    }
    
    init(enemy: Player, view: GameView){
        super.init()
        
        self.gameView = view
        self.enemy = enemy
        
        setupModelScene()
        loadAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupModelScene(){
        
        name = "Golem"
        
        let idleURL = Bundle.main.url(forResource: "art.scnassets/Scenes/Enemies/Golem@Idle", withExtension: "dae")
        
        let idleScene = try! SCNScene(url: idleURL!, options: nil)
        
        for child in idleScene.rootNode.childNodes {
            daeHolderNoder.addChildNode(child)
            
        }
        
        addChildNode(daeHolderNoder)
        
        characterNode = daeHolderNoder.childNode(withName: "CATRigHub002", recursively: true)!
        
    }
    
    private func loadAnimations(){
        loadAnimation(animationType: .walk, scene: "art.scnassets/Scenes/Enemies/Golem@Flight", identifier: "unnamed_animation__1")
        loadAnimation(animationType: .attack1, scene: "art.scnassets/Scenes/Enemies/Golem@Attack(1)", identifier: "Golem@Attack(1)-1")
        loadAnimation(animationType: .dead, scene: "art.scnassets/Scenes/Enemies/Golem@Dead", identifier: "Golem@Dead-1")
        
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
    
    func update(with time:TimeInterval, and scene:SCNScene){
        
        guard let enemy = enemy,!enemy.isDead, !isDead else {return}
        
        //delta time
        if previousUpdateTime == 0.0 {previousUpdateTime = time}
        let deltaTime = Float(min(time-previousUpdateTime, 1/60))
        previousUpdateTime = time
        
        //distance
        let distance = GameUtils.distanceBetweenVectors(vector1: enemy.position, vector2: position)
        
        if distance < noticeDistance && distance > 0.01 {
            let vResult = GameUtils.getCoordinatesNeededToMoveToReachNode(from: position, to: enemy.position)
            let vx = vResult.vX
            let vz = vResult.vZ
            let angle = vResult.angle
            
            //rotate
            let fixedAngle = GameUtils.getFixedRotationAngle(with: angle)
            eulerAngles = SCNVector3Make(0, fixedAngle, 0)
            
            if !isCollideWithEnemy && !isAttacking {
                
                let characterSpeed = deltaTime * moveSpeedLimiter
                
                if vx != 0.0 && vz != 0.0 {
                    position.x += vx * characterSpeed
                    position.z += vz * characterSpeed
                    
                    isWalking = true
                } else {
                    isWalking = false
                }
                
                //update the altitude
                let initialPosition = position
                
                var pos = position
                var endpoint0 = pos
                var endpoint1 = pos
                
                endpoint0.y -= 0.1
                endpoint1.y += 0.08
                
                let results = scene.physicsWorld.rayTestWithSegment(from: endpoint1, to: endpoint0, options: [.collisionBitMask: BitmaskWall, .searchMode: SCNPhysicsWorld.TestSearchMode.closest])
                
                if let result = results.first {
                    
                    let groundAltitude = result.worldCoordinates.y
                    
                    pos.y = groundAltitude
                    
                    position = pos
                } else {
                    position = initialPosition
                }
            } else {
                
                //attack
                if lastAttackTime == 0.0 {
                    lastAttackTime = time
                    attack1()
                }
                
                let timeDiff = time - lastAttackTime
                if timeDiff >= 2.5 {
                    lastAttackTime = timeDiff
                    attack1()
                }
                
            }
            
        } else {
            isWalking = false
        }
        
        
        
    }
    
    //collision
    func setupCollider(scale: CGFloat){
        
        let geometry = SCNCapsule(capRadius: 13, height: 52)
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        
        collider = SCNNode(geometry: geometry)
        collider.name = "golemCollider"
        collider.position = SCNVector3Make(0, 46, 0)
        collider.opacity = 0.0
        
        let shapeGeometry = SCNCapsule(capRadius: 13*scale, height: 52*scale)
        let physicsShape = SCNPhysicsShape(geometry: shapeGeometry, options: nil)
        collider.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
        collider.physicsBody!.categoryBitMask = BitmaskGolem
        collider.physicsBody!.contactTestBitMask = BitmaskPlayer | BitmaskWall | BitmaskPlayerWeapon
        
        gameView.prepare([collider]) { (finished) in
            if finished {
                self.addChildNode(self.collider)
            }
        }
        
    }
    
    //attack
    private var isAttacking = false
    private var lastAttackTime: TimeInterval = 0.0
    private var attackTimer: Timer?
    private var attackFrameCounter = 0
    
    private func attack1(){
        if isAttacking {return}
        
        isAttacking = true
        
        DispatchQueue.main.async {
            self.attackTimer?.invalidate()
            self.attackTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.attackTimerTicked), userInfo: nil, repeats: true)
            self.characterNode.addAnimation(self.attack1Animation, forKey: "attack1")
        }
    }
    
    @objc private func attackTimerTicked(){
        attackFrameCounter += 1
        
        if attackFrameCounter == 10 {
            if isCollideWithEnemy {
                
                enemy.gotHit(with: 15.0)
            }
        }
    }
    
    //battle
    private var hpPoints: Float = 70.0
    private var isDead = false
    
    func gotHit(by node: SCNNode, with hpHitPoints: Float){
        hpPoints -= hpHitPoints
        
        if hpPoints <= 0 {
            die()
        }
    }
    
    private func die(){
        
        isDead = true
        addAnimation(deadAnimation, forKey: "dead")
         
        let wait = SCNAction.wait(duration: 3.0)
        let remove = SCNAction.run { (node) in
            self.removeAllAnimations()
            self.removeAllActions()
            self.removeFromParentNode()
        }
        
        let seq = SCNAction.sequence([wait, remove])
        runAction(seq)
    }
    
}


extension Golem: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        guard let id = anim.value(forKey: "animationId") as? String else {return}
        
        if id == "attack1" {
            attackTimer?.invalidate()
            attackFrameCounter = 0
            isAttacking = false
        }
        
    }
    
}
