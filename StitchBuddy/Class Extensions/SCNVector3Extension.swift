//
//  SCNVector3Extension.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-03.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import ARKit

extension SCNVector3{
    func distance(to targetVector: SCNVector3) -> Float{
        let x1 = self.x
        let x2 = targetVector.x
        let y1 = self.y
        let y2 = targetVector.y
        let z1 = self.z
        let z2 = targetVector.z
        
        return sqrtf( pow((x2 - x1), 2) + pow((y2 - y1), 2) + pow((z2 - z1), 2) )
    }
}
