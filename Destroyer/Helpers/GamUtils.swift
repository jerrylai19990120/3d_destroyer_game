//
//  GamUtils.swift
//  Destroyer
//
//  Created by Jerry Lai on 2021-02-12.
//  Copyright © 2021 Jerry Lai. All rights reserved.
//

import Foundation
import SceneKit

struct GameUtils {
    
    static func distanceBetweenVectors(vector1: SCNVector3, vector2: SCNVector3) -> Float {
        let vector = SCNVector3Make(vector1.x-vector2.x, vector1.y-vector2.y, vector1.z-vector2.z)
        
        return sqrt(pow(vector.x, 2.0)+pow(vector.y, 2.0)+pow(vector.z, 2.0))
    }
    
    static func getCoordinatesNeededToMoveToReachNode(from vector1: SCNVector3, to vector2: SCNVector3) -> (vX: Float, vZ: Float, angle: Float) {
        
        let dx = vector2.x - vector1.x
        let dz = vector2.z - vector1.z
        let angle = atan2(dz, dx)
        
        let vx = cos(angle)
        let vz = sin(angle)
        
        return (vx, vz, angle)
    }
    
    static func getFixedRotationAngle(with angle: Float) -> Float {
        return (Float.pi/2) - angle
    }
}
