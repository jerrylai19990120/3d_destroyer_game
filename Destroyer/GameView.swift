//
//  GameView.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-09.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import SceneKit
import SpriteKit

class GameView: SCNView {
    
    private var skScene: SKScene!
    private var overlayNode = SKNode()
    private var dpadSprite: SKSpriteNode!
    private var attackBtnSprite: SKSpriteNode!
    private var hpBar: SKSpriteNode!
    private let hpMaxWidth: CGFloat = 150.0
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup2DOverlay()
    }
    
    override func layoutSubviews() {
        
        layout2DOverlay()
    }
    
    deinit {
        
    }
    
    //functions
    
    private func setup2DOverlay(){
        
        let w = bounds.size.width
        let h = bounds.size.height
        
        skScene = SKScene(size: CGSize(width: w, height: h))
        
        skScene.scaleMode = .resizeFill
        
        skScene.addChild(overlayNode)
        overlayNode.position = CGPoint(x: 0.0, y: h)
        
        setupDpad(with: skScene)
        setupAttackButton(with: skScene)
        setupHpBar(with: skScene)
        
        overlaySKScene = skScene
        skScene.isUserInteractionEnabled = true
        
    }
    
    private func layout2DOverlay(){
        overlayNode.position = CGPoint(x: 0.0, y: bounds.size.height)
    }
    
    //D-pad
    
    private func setupDpad(with scene: SKScene){
        
        dpadSprite = SKSpriteNode(imageNamed: "art.scnassets/Assets/dpad.png")
        dpadSprite.position = CGPoint(x: 10.0, y: 10.0)
        dpadSprite.xScale = 1.0
        dpadSprite.yScale = 1.0
        dpadSprite.anchorPoint = CGPoint(x: 0, y: 0)
        dpadSprite.size = CGSize(width: 150.0, height: 150.0)
        scene.addChild(dpadSprite)
        
    }
    
    func virtualDPadBounds() -> CGRect {
        
        var virtualDPadBounds = CGRect(x: 10.0, y: 10.0, width: 150.0, height: 150.0)
        
        virtualDPadBounds.origin.y = bounds.size.height - virtualDPadBounds.size.height + virtualDPadBounds.origin.y
        
        return virtualDPadBounds
    }
    
    //attack button
    
    private func setupAttackButton(with scene: SKScene) {
        
        attackBtnSprite = SKSpriteNode(imageNamed: "art.scnassets/Assets/attack1.png")
        
        attackBtnSprite.position = CGPoint(x: bounds.size.height - 110.0, y: 50)
        
        attackBtnSprite.xScale = 1.0
        attackBtnSprite.yScale = 1.0
        attackBtnSprite.size = CGSize(width: 60.0, height: 60.0)
        attackBtnSprite.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        
        attackBtnSprite.name = "attackButton"
        scene.addChild(attackBtnSprite)
    }
    
    func virtualAttackBtnBounds() -> CGRect {
        
        var virtualBounds = CGRect(x: bounds.width-110, y: 50, width: 60, height: 60)
        
        virtualBounds.origin.y = bounds.size.height - virtualBounds.size.height - virtualBounds.origin.y
        
        return virtualBounds
    }
    
    
    //Health Bar
    private func setupHpBar(with scene:SKScene){
        
        hpBar = SKSpriteNode(color: UIColor.green, size: CGSize(width: hpMaxWidth, height: 20))
        
        hpBar.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        hpBar.position = CGPoint(x: 15.0, y: bounds.width - 35.0)
        hpBar.xScale = 1.0
        hpBar.yScale = 1.0
        scene.addChild(hpBar)
        
    }
    
    
}
