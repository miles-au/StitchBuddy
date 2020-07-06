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
        leftEdge.isHidden = false
        rightEdge.isHidden = false
        leftEdge.handleNode?.isHidden = false
        rightEdge.handleNode?.isHidden = false
        instructionsLabel.text = "Drag the handles to the edges of the fabric"
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
        print("tap")
        print("is placing corner: \(isPlacingCorner)")
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
            
            let (leftPosition, rightPosition) = getDefaultHandlePositions(from: cornerNode.worldPosition)
            
            leftEdge.update(pivotPoint: cornerNode.position, outerPoint: leftPosition)
            rightEdge.update(pivotPoint: cornerNode.position, outerPoint: rightPosition)
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
        } else if isPlacingEdges{
            // left side
            
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
