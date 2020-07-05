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
        handleNode = EdgeHandleNode()
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
            handleNode?.isHidden = false
            handleNode?.worldPosition = outerPoint
        }
    }
    
    // recursive function to get first edge node from node or node's parents
    static func getFirstEdgeNode(from node: SCNNode) -> EdgeNode?{
        if let edgenode = node as? EdgeNode{
            return edgenode
        } else if let parent = node.parent{
            return getFirstEdgeNode(from: parent)
        } else {
            return nil
        }
    }
}
