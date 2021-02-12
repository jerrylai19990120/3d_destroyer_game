//
//  Golem.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-12.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import Foundation
import SceneKit

class Golem:SCNNode {
    
    init(enemy: Player, view: GameView){
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
