//
//  ViewController.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-06-28.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    private var screenCenter: CGPoint!
    
    private var planeAnchor: ARAnchor?
    
    let guidanceOverlay = ARCoachingOverlayView()
    
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    // Corner Placement
    private var isPlacingCorner = false
    private let cornerCursor = CornerCursor()
    private var cornerNode = CornerNode()
    
    // Edge Placement
    private var isPlacingEdges = false
    private let leftEdge = EdgeNode()
    private let rightEdge = EdgeNode()
    
    // Inset Placement
    private var isPlacingInsets = false
    private let leftInset = EdgeNode()
    private let rightInset = EdgeNode()
    @IBOutlet weak var insetPicker: UIPickerView!
    let pickerChoices: [Double] = {
        var array = [Double]()
        for i in stride(from: 0.0, through: 10.0, by: 0.5) {
            array.append(i)
        }
        return array
    }()
    
    // diagonal
    private let diagonalEdge = EdgeNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenCenter = view.center
        
        // setup sceneview
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = false
        
        // setup corner node
        cornerCursor.isHidden = true
        
        // setup edge and handle nodes
        sceneView.scene.rootNode.addChildNode(cornerCursor)
        sceneView.scene.rootNode.addChildNode(cornerNode)
        leftEdge.createHandle()
        rightEdge.createHandle()
        sceneView.scene.rootNode.addChildNode(leftEdge)
        sceneView.scene.rootNode.addChildNode(rightEdge)
        
        // setup insets
        insetPicker.delegate = self
        insetPicker.dataSource = self
        sceneView.scene.rootNode.addChildNode(leftInset)
        sceneView.scene.rootNode.addChildNode(rightInset)
        
        sceneView.scene.rootNode.addChildNode(diagonalEdge)
        
        // setup gestures
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            // ARSession Config
            let sessionConfiguration: ARWorldTrackingConfiguration = {
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = .horizontal
                return config
            }()
            
            // Add coaching overlay
            self.setOverlay(automatically: true, forDetectionType: .horizontalPlane)
            
            sceneView.session.run(sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        } else {
            print("Sorry, your device doesn't support ARKit")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func updateIsPlacingCorner(to isPlacingCorner: Bool){
        self.isPlacingCorner = isPlacingCorner
        instructionsLabel.text = "Tap the screen to mark the corner of the fabric."
        cornerCursor.isHidden = !isPlacingCorner
        cornerNode.setHighlight(to: isPlacingCorner)
    }
    
    func updateIsPlacingEdges(to isPlacingEdges: Bool){
        self.isPlacingEdges = isPlacingEdges
        leftEdge.isHidden = !isPlacingEdges
        rightEdge.isHidden = !isPlacingEdges
        leftEdge.handleNode?.isHidden = !isPlacingEdges
        rightEdge.handleNode?.isHidden = !isPlacingEdges
        instructionsLabel.text = "Drag the handles to the edges of the fabric"
    }
    
    func resetEdgesToDefault(){
        let (leftPosition, rightPosition) = getDefaultHandlePositions(from: cornerNode.worldPosition)
        
        leftEdge.update(pivotPoint: cornerNode.position, outerPoint: leftPosition)
        rightEdge.update(pivotPoint: cornerNode.position, outerPoint: rightPosition)
    }
    
    // returns starting positions for left handle, right handle
    func initialHandlePositions() -> (CGPoint, CGPoint){
        return (CGPoint(x: view.frame.width * 0.25, y: view.frame.height * 0.25), CGPoint(x: view.frame.width * 0.75, y: view.frame.height * 0.25))
    }
    
    // returns left handle, right handle
    func getDefaultHandlePositions(from pivotPoint: SCNVector3) -> (SCNVector3, SCNVector3){
        let (leftPoint, rightPoint) = initialHandlePositions()
        
        // hit results
        guard let leftResult = hitPlane(at: leftPoint), let rightResult = hitPlane(at: rightPoint) else { return (SCNVector3(0, pivotPoint.y, 0), SCNVector3(0, pivotPoint.y, 0)) }
        
        let leftPosition = SCNVector3(leftResult.worldTransform.columns.3.x,
                                      pivotPoint.y,
                                      leftResult.worldTransform.columns.3.z)
        
        let rightPosition = SCNVector3(rightResult.worldTransform.columns.3.x,
                                       pivotPoint.y,
                                       rightResult.worldTransform.columns.3.z)
        
        return (leftPosition, rightPosition)
    }
    
    func updateIsPlacingInsets(to isPlacingInsets: Bool){
        self.isPlacingInsets = isPlacingInsets
        instructionsLabel.text = "Pick your seam allowances."
        
        leftEdge.isHidden = !isPlacingInsets
        rightEdge.isHidden = !isPlacingInsets
        diagonalEdge.isHidden = !isPlacingInsets
        
        insetPicker.isHidden = !isPlacingInsets
    }
    
    @objc private func viewPanned(_ gesture: UIPanGestureRecognizer) {
        if planeAnchor == nil { return }
        
        let hitLocation = gesture.location(in: sceneView)
        if let node = node(at: hitLocation), node.categoryBitMask == ARConstants.Interactive.yes.rawValue{
            if let edgeNode = EdgeNode.getFirstEdgeNode(from: node){
                guard let hitResult = hitPlane(at: gesture.location(in: sceneView)) else { return }
                let outerPoint = SCNVector3(hitResult.worldTransform.columns.3.x,
                                            cornerNode.worldPosition.y,
                                            hitResult.worldTransform.columns.3.z)
                edgeNode.update(pivotPoint: cornerNode.worldPosition, outerPoint: outerPoint)
            }
        }
    }
    
    @objc private func viewTapped(_ recognizer: UITapGestureRecognizer) {
        if(isPlacingCorner){
            doneButton.isHidden = false
            guard let result = hitPlane(at: screenCenter) else { return }
            cornerNode.position = SCNVector3(result.worldTransform.columns.3.x,
                                             result.worldTransform.columns.3.y,
                                             result.worldTransform.columns.3.z)
            cornerNode.isHidden = false
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        if (isPlacingCorner){
            updateIsPlacingCorner(to: false)
            updateIsPlacingEdges(to: true)
            resetEdgesToDefault()
        } else if(isPlacingEdges){
            updateIsPlacingEdges(to: false)
            updateIsPlacingInsets(to: true)
            doneButton.isHidden = true
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeAnchor = anchor
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        planeAnchor = anchor
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isPlacingCorner{
            guard let result = hitPlane(at: screenCenter) else { return }
            cornerCursor.position = SCNVector3(result.worldTransform.columns.3.x,
                                               result.worldTransform.columns.3.y,
                                               result.worldTransform.columns.3.z)
        }
    }
    
    private func hitPlane(at position: CGPoint) -> ARHitTestResult?{
        return sceneView.hitTest(position, types: [.existingPlane]).first
    }
    
    private func node(at position: CGPoint) -> SCNNode? {
        if let firstNode = sceneView.hitTest(position, options: nil).first?.node{
            return firstNode
        }
        return nil
    }
}

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
        
        var leftVector = SCNVector3.from(point: cornerPoint, toPoint: rightHandlePosition) // move the point away from the left vector
        var rightVector = SCNVector3.from(point: cornerPoint, toPoint: leftHandlePosition) // move the point away from the right vector
        
        return (leftVector, rightVector)
    }
    
    func showInsets(){
        leftInset.updateColor(to: ARConstants.leftColor)
        rightInset.updateColor(to: ARConstants.rightColor)
        
        leftInset.isHidden = false
        rightInset.isHidden = false
    }
}
