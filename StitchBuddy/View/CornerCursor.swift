//
//  CornerCursor.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-03.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import ARKit

class CornerCursor: SCNNode{
    
    private let height = ARConstants.defaultHeight / 2
    
    // outer translucent cylinder
    private let outerRadius = CGFloat(0.05)
    let outerMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.transparency = 0.3
        return material
    }()
    
    // inner opaque cylinder
    private let innerRadius = ARConstants.lineWidth / 2
    let innerMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.transparency = 1
        return material
    }()
    
    override init() {
        super.init()
        _createCursor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _createCursor()
    }
    
    func _createCursor(){
        createOuterCylinder()
        createinnerCylinder()
        isHidden = true
    }
    
    func createOuterCylinder(){
        let cylinder = SCNCylinder(radius: outerRadius, height: height)
        cylinder.materials = [outerMaterial]
        addChildNode(SCNNode(geometry: cylinder))
    }
    
    func createinnerCylinder(){
        let cylinder = SCNCylinder(radius: innerRadius, height: height)
        cylinder.materials = [innerMaterial]
        addChildNode(SCNNode(geometry: cylinder))
    }
}
