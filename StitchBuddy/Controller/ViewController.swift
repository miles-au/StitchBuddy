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

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var cornerPlacementView: UIView!
    
    private var screenCenter: CGPoint!
    
    private var planeAnchor: ARAnchor?
    
    private let guidanceOverlay = ARCoachingOverlayView()
    
    // Corner Placement
    private var isPlacingCorner = false
    private let cornerCursor = CornerCursor()
    private var cornerNode = CornerNode()
    @IBOutlet weak var placeCornerButton: UIButton!
    @IBOutlet weak var donePlacingCornerButton: UIButton!
    
    // Edge Placement
    private var isPlacingEdges = false
    private let leftEdge = EdgeNode()
    private let rightEdge = EdgeNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = false
        screenCenter = view.center
        cornerCursor.isHidden = true
        
        sceneView.scene.rootNode.addChildNode(cornerCursor)
        sceneView.scene.rootNode.addChildNode(cornerNode)
//        leftEdge.color = ARConstants.leftColor
//        rightEdge.color = ARConstants.rightColor
        leftEdge.createHandle()
        rightEdge.createHandle()
        sceneView.scene.rootNode.addChildNode(leftEdge)
        sceneView.scene.rootNode.addChildNode(rightEdge)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // round button corners
        placeCornerButton.layer.cornerRadius = placeCornerButton.frame.height / 2
        donePlacingCornerButton.layer.cornerRadius = donePlacingCornerButton.frame.height / 2
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            // ARSession Config
            let sessionConfiguration: ARWorldTrackingConfiguration = {
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = .horizontal
                return config
            }()
            
            // Add coaching overlay
            setOverlay(automatically: true, forDetectionType: .horizontalPlane)
            
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
        cornerPlacementView.isHidden = !isPlacingCorner
        cornerCursor.isHidden = !isPlacingCorner
    }
    
    @IBAction func placeCornerButtonPressed(_ sender: UIButton) {
        donePlacingCornerButton.isHidden = false
        guard let result = hitPlane(at: screenCenter) else { return }
        cornerNode.position = SCNVector3(result.worldTransform.columns.3.x,
                                           result.worldTransform.columns.3.y,
                                           result.worldTransform.columns.3.z)
        cornerNode.isHidden = false
    }
    
    @IBAction func donePlacingCornerButtonPressed(_ sender: UIButton) {
        updateIsPlacingCorner(to: false)
        cornerNode.unhighlight()
        
        let (leftPosition, rightPosition) = getDefaultHandlePositions(from: cornerNode.worldPosition)
        leftEdge.isHidden = false
        rightEdge.isHidden = false
        
        leftEdge.update(pivotPoint: cornerNode.position, outerPoint: leftPosition)
        rightEdge.update(pivotPoint: cornerNode.position, outerPoint: rightPosition)
    }
    
    // returns left handle, right handle
    func getDefaultHandlePositions(from pivotPoint: SCNVector3) -> (SCNVector3, SCNVector3){
        let leftPoint = CGPoint(x: view.frame.width * 0.25, y: view.frame.height * 0.25)
        let rightPoint = CGPoint(x: view.frame.width * 0.75, y: view.frame.height * 0.25)
        
        // hit results
        guard let leftResult = hitPlane(at: leftPoint), let rightResult = hitPlane(at: rightPoint) else { return (SCNVector3(0, pivotPoint.y, 0), SCNVector3(0, pivotPoint.y, 0)) }
        
        let leftPosition = SCNVector3(leftResult.worldTransform.columns.3.x,
                                      leftResult.worldTransform.columns.3.y,
                                      leftResult.worldTransform.columns.3.z)
        
        let rightPosition = SCNVector3(rightResult.worldTransform.columns.3.x,
                                      rightResult.worldTransform.columns.3.y,
                                      rightResult.worldTransform.columns.3.z)
        
        return (leftPosition, rightPosition)
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeAnchor = anchor
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        planeAnchor = anchor
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let result = hitPlane(at: screenCenter) else { return }
        cornerCursor.position = SCNVector3(result.worldTransform.columns.3.x,
                                           result.worldTransform.columns.3.y,
                                           result.worldTransform.columns.3.z)
    }
    
    private func hitPlane(at position: CGPoint) -> ARHitTestResult?{
        return sceneView.hitTest(position, types: [.existingPlane]).first
    }
}

// MARK: - Coaching Overlay
extension ViewController: ARCoachingOverlayViewDelegate{
    func setOverlay(automatically: Bool, forDetectionType goal: ARCoachingOverlayView.Goal){
      
      //1. Link The GuidanceOverlay To Our Current Session
      guidanceOverlay.session = sceneView.session
      guidanceOverlay.delegate = self
      sceneView.addSubview(guidanceOverlay)
      
      //2. Set It To Fill Our View
      NSLayoutConstraint.activate([
        NSLayoutConstraint(item:  guidanceOverlay, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item:  guidanceOverlay, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item:  guidanceOverlay, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item:  guidanceOverlay, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        ])
      
      guidanceOverlay.translatesAutoresizingMaskIntoConstraints = false
      
      //3. Enable The Overlay To Activate Automatically Based On User Preference
      guidanceOverlay.activatesAutomatically = automatically
      
      //4. Set The Purpose Of The Overlay Based On The User Preference
      guidanceOverlay.goal = goal
      
    }
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        updateIsPlacingCorner(to: false)
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        updateIsPlacingCorner(to: true)
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        updateIsPlacingCorner(to: false)
    }

}
