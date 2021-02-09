//
//  GameViewController.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-09.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import UIKit
import SceneKit

enum GameState{
    case loading, playing
}

class GameViewController: UIViewController {
    
    var gameView: GameView { return view as! GameView }
    var mainScene: SCNScene!
    
    var gameState: GameState = .loading
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        
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
        
        mainScene = SCNScene(named: "art.scnassets/Scenes/Stage1.scn")
        gameView.scene = mainScene
        gameView.isPlaying = true
    }
    
    //Walls
    
    //Camera
    
    //player
    
    //touches + movement
    
    //game loop functions
    
    //enemies

}

//Extensions
