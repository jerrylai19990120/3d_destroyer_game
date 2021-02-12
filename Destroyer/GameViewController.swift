//
//  GameViewController.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-09.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import UIKit
import SceneKit

let BitmaskPlayer = 1
let BitmaskPlayerWeapon = 2
let BitmaskWall = 64
let BitmaskGolem = 3

enum GameState{
    case loading, playing
}

class GameViewController: UIViewController {
    
    var gameView: GameView { return view as! GameView }
    var mainScene: SCNScene!
    
    var gameState: GameState = .loading
    
    private var player: Player?
    private var cameraStick: SCNNode!
    private var cameraXHolder: SCNNode!
    private var cameraYHolder: SCNNode!
    private var lightStick: SCNNode!
    
    private var cameraTouch: UITouch?
    
    
    private var controllerStoredDirection = float2(0.0)
    private var padTouch: UITouch?
    
    //collisions
    private var maxPenetrationDistance = CGFloat(0.0)
    private var replacementPosition = [SCNNode:SCNVector3]()
    
    //enemies
    private var golemPositionArray = [String:SCNVector3]()
     

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupPlayer()
        setupCamera()
        setupLight()
        setupWallBitmasks()
        setupEnemies()
        
        gameState = .playing
    }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    //Scenes
    private func setupScene(){
        
        gameView.allowsCameraControl = true
        gameView.antialiasingMode = .multisampling4X
        gameView.delegate = self
        
        mainScene = SCNScene(named: "art.scnassets/Scenes/Stage1.scn")
        mainScene.physicsWorld.contactDelegate = self
        
        
        gameView.scene = mainScene
        gameView.isPlaying = true
        
    }
    
    //Walls
    private func setupWallBitmasks(){
        
        var collisionNodes = [SCNNode]()
        
        mainScene.rootNode.enumerateChildNodes { (node, _) in
            
            switch node.name {
            case let .some(s) where s.range(of: "collision") != nil:
                collisionNodes.append(node)
            default:
                break
            }
        }
        
        for node in collisionNodes {
            node.physicsBody = SCNPhysicsBody.static()
            node.physicsBody!.categoryBitMask = BitmaskWall
            node.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options: [.type: SCNPhysicsShape.ShapeType.concavePolyhedron as NSString])
            
        }
    }
    
    //Camera
    private func setupCamera(){
        
        cameraStick = mainScene.rootNode.childNode(withName: "CameraStick", recursively: false)!
        cameraXHolder = mainScene.rootNode.childNode(withName: "xHolder", recursively: true)
        cameraYHolder = mainScene.rootNode.childNode(withName: "yHolder", recursively: true)
    }
    
    private func panCamera(_ direction: float2) {
        
        var directionToPan = direction
        
        directionToPan *= float2(1.0, -1.0)
        
        let panReducer = Float(0.005)
        
        let currX = cameraXHolder.rotation
        let xRotationValue = currX.w - directionToPan.x * panReducer
        
        cameraXHolder.rotation = SCNVector4Make(0, 1, 0, xRotationValue)
        
        let currY = cameraYHolder.rotation
        var yRotationValue = currY.w + directionToPan.y * panReducer
        
        if yRotationValue < -0.94 { yRotationValue = -0.94 }
        if yRotationValue > 0.66 { yRotationValue = 0.66 }
 
        cameraYHolder.rotation = SCNVector4Make(1, 0, 0, yRotationValue)
    }
    
    private func setupLight(){
        lightStick = mainScene.rootNode.childNode(withName: "LightStick", recursively: false)!
    }
    
    //player
    private func setupPlayer(){
        
        player = Player()
        player!.scale = SCNVector3Make(0.0026, 0.0026, 0.0026)
        
        player!.position = SCNVector3Make(0.0, 0.0, 0.0)
        player!.rotation = SCNVector4Make(0, 1, 0, Float.pi)
        
        mainScene.rootNode.addChildNode(player!)
        
        player!.setupColliders(with: 0.0026)
        player?.setupWeaponCollider(with: 0.0026)
    }
    
    //touches + movement
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if gameView.virtualDPadBounds().contains(touch.location(in: gameView)) {
                if padTouch == nil {
                    padTouch = touch
                    controllerStoredDirection = float2(0.0)
                } else if cameraTouch == nil {
                    cameraTouch = touches.first
                    
                }
            } else if gameView.virtualAttackBtnBounds().contains(touch.location(in: gameView)) {
                player!.attack1()
            } else if cameraTouch == nil {
                cameraTouch = touches.first
            }
            
            if padTouch != nil {
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = padTouch {
            let displacement = float2(touch.location(in: view)) - float2(touch.previousLocation(in: view))
            let vMix = mix(controllerStoredDirection, displacement, t: 0.1)
            let vClamp = clamp(vMix, min: -1.0, max: 1.0)
            
            controllerStoredDirection = vClamp

        } else if let touch = cameraTouch {
            let displacement = float2(touch.location(in: view)) - float2(touch.previousLocation(in: view))
            panCamera(displacement)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        padTouch = nil
        controllerStoredDirection = float2(0.0)
        cameraTouch = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        padTouch = nil
        controllerStoredDirection = float2(0.0)
        cameraTouch = nil
    }
    
    private func characterDirection() -> float3 {
        var direction = float3(controllerStoredDirection.x, 0.0, controllerStoredDirection.y)
        if let pov = gameView.pointOfView {
            
            let p1 = pov.presentation.convertPosition(SCNVector3(direction), to: nil)
            let p0 = pov.presentation.convertPosition(SCNVector3Zero, to: nil)
            
            direction = float3(Float(p1.x-p0.x), 0.0, Float(p1.z-p0.z))
            
            if direction.x != 0.0 || direction.z != 0.0 {
                direction = normalize(direction)
            }
        }
        return direction
    }
    //game loop functions
    
    func updateFollowersPositions(){
        cameraStick.position = SCNVector3Make(player!.position.x, 0.0, player!.position.z)
        lightStick.position = SCNVector3Make(player!.position.x, 0.0, player!.position.z)
    }
    
    //enemies
    private func setupEnemies(){
        let enemies = mainScene.rootNode.childNode(withName: "Enemies", recursively: false)!
        
        for child in enemies.childNodes {
            golemPositionArray[child.name!] = child.position
        }
        
        setupGolems()
    }
    
    private func setupGolems(){
        
        let golemScale:Float = 0.0083
        
        let golem1 = Golem(enemy: player!, view: gameView)
        golem1.scale = SCNVector3Make(golemScale, golemScale, golemScale)
        golem1.position = golemPositionArray["golem1"]!
        
        let golem2 = Golem(enemy: player!, view: gameView)
        golem2.scale = SCNVector3Make(golemScale, golemScale, golemScale)
        golem2.position = golemPositionArray["golem2"]!
        
        let golem3 = Golem(enemy: player!, view: gameView)
        golem3.scale = SCNVector3Make(golemScale, golemScale, golemScale)
        golem3.position = golemPositionArray["golem3"]!
        
        gameView.prepare([golem1, golem2, golem3]) { (finished) in
            self.mainScene.rootNode.addChildNode(golem1)
            self.mainScene.rootNode.addChildNode(golem2)
            self.mainScene.rootNode.addChildNode(golem3)
            
            golem1.setupCollider(scale: CGFloat(golemScale))
            golem2.setupCollider(scale: CGFloat(golemScale))
            golem3.setupCollider(scale: CGFloat(golemScale))
        }
    }
    
    //collisions
    private func characterNode(_ characterNode:SCNNode, hitwall wall: SCNNode, withContact contact:SCNPhysicsContact){
        
        if characterNode.name != "collider" && characterNode.name != "golemCollider" {return}
        
        if maxPenetrationDistance > contact.penetrationDistance {return}
        
        maxPenetrationDistance = contact.penetrationDistance
        var characterPosition = float3(characterNode.parent!.position)
        
        var positionOffset = float3(contact.contactNormal) * Float(contact.penetrationDistance)
        
        positionOffset.y = 0
        characterPosition += positionOffset
        
        replacementPosition[characterNode.parent!] = SCNVector3(characterPosition)
        
    }

}

//Extensions
extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if gameState != .playing {return}
        
        //reset
        replacementPosition.removeAll()
        maxPenetrationDistance = 0.0
        
        let scene = gameView.scene!
        let direction = characterDirection()
        
        player!.walkInDirection(direction, time: time, scene: scene)
        
        updateFollowersPositions()
        
        mainScene.rootNode.enumerateChildNodes { (node, _) in
            if let name = node.name {
                switch name {
                case "Golem":
                    (node as! Golem).update(with: time, and: scene)
                default:
                    break
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        if gameState != .playing {return}
        
        for (node, position) in replacementPosition {
            node.position = position
        }
    }
    
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if gameState != .playing {return}
        
        contact.match(BitmaskWall) { (matching, other) in
            self.characterNode(other, hitwall: matching, withContact: contact)
        }
        
        contact.match(BitmaskGolem) { (matching, other) in
            let golem = matching.parent as! Golem
            if other.name == "collider" {
                golem.isCollideWithEnemy = true
            }
            
            if other.name == "weaponCollider" { player!.weaponCollide(with: golem)}
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
        contact.match(BitmaskWall) { (matching, other) in
            self.characterNode(other, hitwall: matching, withContact: contact)
        }
        
        contact.match(BitmaskGolem) { (matching, other) in
            let golem = matching.parent as! Golem
            if other.name == "collider" {
                golem.isCollideWithEnemy = true
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        contact.match(BitmaskGolem) { (matching, other) in
            let golem = matching.parent as! Golem
            if other.name == "collider" {
                golem.isCollideWithEnemy = false
            }
            if other.name == "weaponCollider" {
                player!.weaponUnCollide(with: golem)
            }
        }
    }
    
}
