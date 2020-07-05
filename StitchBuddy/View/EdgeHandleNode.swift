//
//  EdgeHandleNode.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-04.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import ARKit

class EdgeHandleNode: SCNNode{
    let height = ARConstants.defaultHeight
    
    override init() {
        super.init()
        createHandle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createHandle()
    }
    
    func createHandle(){
        // outer cylinder
        let outerCylinder = SCNCylinder(radius: CGFloat(0.05), height: height)
        let outerMaterial = SCNMaterial()
        outerMaterial.diffuse.contents = ARConstants.actionColor
        outerMaterial.transparency = 0.3
        outerCylinder.materials = [outerMaterial]
        geometry = outerCylinder
        categoryBitMask = ARConstants.Interactive.yes.rawValue
        isHidden = true
        
        // inner cylinder
        let innerCylinder = SCNCylinder(radius: CGFloat(0.01), height: height)
        let material = SCNMaterial()
        material.diffuse.contents = ARConstants.actionColor
        innerCylinder.materials = [material]
        let innerNode = SCNNode(geometry: innerCylinder)
        innerNode.categoryBitMask = ARConstants.Interactive.yes.rawValue
        addChildNode(innerNode)
    }
}
