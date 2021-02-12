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
        setupObservers()
    }
    
    override func layoutSubviews() {
        
        layout2DOverlay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    private func setupObservers(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(hpDidChange), name: Notification.Name("hpChanged"), object: nil)
    }
    
    @objc private func hpDidChange(notif: Notification){
        guard let userInfo = notif.userInfo as? [String:Any], let playerMaxHp = userInfo["playerMaxHp"] as? Float, let currentHp = userInfo["currentHp"] as? Float else {return}
        
        let v1 = CGFloat(playerMaxHp)
        let v2 = hpMaxWidth
        let v3 = CGFloat(currentHp)
        var x: CGFloat = 0.0
        
        x = (v2*v3) / v1
        
        if x <= hpMaxWidth / 3.5 {
            hpBar.color = UIColor.red
            
        } else if x <= hpMaxWidth / 2 {
            hpBar.color = UIColor.orange
        }
        
        if x < 0 { x=0 }
        
        let reduceAction = SKAction.resize(toWidth: x, duration: 0.3)
        hpBar.run(reduceAction)
        
    }
    
    
}
