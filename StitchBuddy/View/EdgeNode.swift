//
//  EdgeNode.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-03.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import ARKit

class EdgeNode: SCNNode{
    let height = ARConstants.defaultHeight
    var lineNode: SCNNode?
    var handleNode: SCNNode?
    var color: UIColor?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func createHandle(){
        let sphere = SCNSphere(radius: CGFloat(0.01))
        let material = SCNMaterial()
        material.diffuse.contents = ARConstants.actionColor
        sphere.materials = [material]
        handleNode = SCNNode(geometry: sphere)
        addChildNode(handleNode!)
    }
    
    func update(pivotPoint: SCNVector3, outerPoint: SCNVector3){
        // update dimensions and color
        let distance = pivotPoint.distance(to: outerPoint)
        let prism = SCNBox(width: ARConstants.lineWidth, height: ARConstants.defaultHeight, length: CGFloat(distance), chamferRadius: 0)
        if color != nil{
            let material = SCNMaterial()
            material.diffuse.contents = color
            prism.materials = [material]
        }
        geometry = prism
        
        // update position to halfway between the two points
        let halfwayPoint = SCNVector3((outerPoint.x - pivotPoint.x) / 2 + pivotPoint.x,
                                  pivotPoint.y,
                                  (outerPoint.z - pivotPoint.z) / 2 + pivotPoint.z)
        worldPosition = halfwayPoint
        
        // rotate to "look" at pivot point
        look(at: pivotPoint, up: SCNVector3(0,1,0), localFront: SCNVector3(0,0,1))
        
        // move handle if necessary
        if handleNode != nil{
            handleNode?.worldPosition = outerPoint
        }
    }
}
