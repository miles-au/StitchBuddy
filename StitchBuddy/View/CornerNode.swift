//
//  CornerNode.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-03.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class CornerNode: SCNNode{
    
    private let height = ARConstants.defaultHeight
    
    // outer translucent cylinder
    private var outerCylinder: SCNNode?
    private let outerRadius = CGFloat(0.05)
    let outerMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = ARConstants.actionColor
        material.lightingModel = .constant
        material.transparency = 0.3
        return material
    }()
    
    // inner opaque cylinder
    private var innerCylinder: SCNNode?
    private let innerRadius = ARConstants.lineWidth / 2
    let innerMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = ARConstants.actionColor
        material.lightingModel = .constant
        material.transparency = 1
        return material
    }()
    
    override init() {
        super.init()
        createCursor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createCursor()
    }
    
    func createCursor(){
        createOuterCylinder()
        createinnerCylinder()
        isHidden = true
    }
    
    func createOuterCylinder(){
        let cylinder = SCNCylinder(radius: outerRadius, height: height)
        outerCylinder = SCNNode(geometry: cylinder)
        cylinder.materials = [outerMaterial]
        addChildNode(outerCylinder!)
    }
    
    func createinnerCylinder(){
        let cylinder = SCNCylinder(radius: innerRadius, height: height)
        innerCylinder = SCNNode(geometry: cylinder)
        cylinder.materials = [innerMaterial]
        addChildNode(innerCylinder!)
    }
    
    func setHighlight(to highlight: Bool){
        if highlight{
            outerCylinder?.isHidden = false
            innerCylinder?.geometry?.materials.first?.diffuse.contents = UIColor.systemYellow
        }else{
            outerCylinder?.isHidden = true
            innerCylinder?.geometry?.materials.first?.diffuse.contents = UIColor.white
        }
    }
}
