//
//  ARViewController+PickerView.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-06.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import UIKit
import ARKit

// MARK: - PickerView
extension ARViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title: String = String(format:"%.1f", pickerChoices[row])
        let color = component == 0 ? ARConstants.leftColor : ARConstants.rightColor
        return NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: color])
    }
}

extension ARViewController: UIPickerViewDelegate{
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // get offsets in meters
        let leftOffset = pickerChoices[insetPicker.selectedRow(inComponent: 0)] / 100
        let rightOffset = pickerChoices[insetPicker.selectedRow(inComponent: 1)] / 100
        
        drawInsets(for: leftOffset, for: rightOffset)
    }
    
    func drawInsets(for leftOffset: Double, for rightOffset: Double){
        let cornerPoint = cornerNode.worldPosition
        
        // get handle positions
        guard let (leftHandlePosition, rightHandlePosition) = getEdgeHandlePositions() as? (SCNVector3, SCNVector3) else { return }
        
        // get offset vectors
        guard var (leftOffsetVector, rightOffsetVector) = getEdgeVectors() as? (SCNVector3, SCNVector3) else { return }
        
        // scale the vector
        leftOffsetVector.x = (leftOffsetVector.x / cornerPoint.distance(to: rightHandlePosition)) * Float(leftOffset)
        leftOffsetVector.z = (leftOffsetVector.z / cornerPoint.distance(to: rightHandlePosition)) * Float(leftOffset)
        
        rightOffsetVector.x = (rightOffsetVector.x / cornerPoint.distance(to: leftHandlePosition)) * Float(rightOffset)
        rightOffsetVector.z = (rightOffsetVector.z / cornerPoint.distance(to: leftHandlePosition)) * Float(rightOffset)
        
        // apply offset to inset edges
        let intersectionPoint = SCNVector3(cornerPoint.x + leftOffsetVector.x + rightOffsetVector.x,
                                           cornerPoint.y,
                                           cornerPoint.z + leftOffsetVector.z + rightOffsetVector.z)
        
        let leftInsetOuterPoint = SCNVector3(leftHandlePosition.x + leftOffsetVector.x,
                                             cornerPoint.y,
                                             leftHandlePosition.z + leftOffsetVector.z)
        let rightInsetOuterPoint = SCNVector3(rightHandlePosition.x + rightOffsetVector.x,
                                              cornerPoint.y,
                                              rightHandlePosition.z + rightOffsetVector.z)
        
        // get worldPositions for diagonal edge
        let diagonalLeftPosition = SCNVector3(cornerPoint.x + leftOffsetVector.x * 2,
                                              cornerPoint.y,
                                              cornerPoint.z + leftOffsetVector.z * 2)
        let diagonalRightPosition = SCNVector3(cornerPoint.x + rightOffsetVector.x * 2,
                                               cornerPoint.y,
                                               cornerPoint.z + rightOffsetVector.z * 2)
        
        // update the edges
        leftInset.update(pivotPoint: intersectionPoint, outerPoint: leftInsetOuterPoint)
        rightInset.update(pivotPoint: intersectionPoint, outerPoint: rightInsetOuterPoint)
        diagonalEdge.update(pivotPoint: diagonalLeftPosition, outerPoint: diagonalRightPosition)
        
        // show insets
        showInsets()
        
        diagonalEdge.updateColor(to: ARConstants.actionColor)
        diagonalEdge.isHidden = false
    }
    
    func getEdgeHandlePositions() -> (SCNVector3?, SCNVector3?){
        return (leftEdge.handleNode?.worldPosition, rightEdge.handleNode?.worldPosition)
    }
    
    func getEdgeVectors() -> (SCNVector3?, SCNVector3?){
        guard let (leftHandlePosition, rightHandlePosition) = getEdgeHandlePositions() as? (SCNVector3, SCNVector3) else { return (nil, nil) }
        
        let cornerPoint = cornerNode.worldPosition
        
        let leftVector = SCNVector3.from(point: cornerPoint, toPoint: rightHandlePosition) // move the point away from the left vector
        let rightVector = SCNVector3.from(point: cornerPoint, toPoint: leftHandlePosition) // move the point away from the right vector
        
        return (leftVector, rightVector)
    }
    
    func showInsets(){
        leftInset.updateColor(to: ARConstants.leftColor)
        rightInset.updateColor(to: ARConstants.rightColor)
        
        leftInset.isHidden = false
        rightInset.isHidden = false
    }
}
