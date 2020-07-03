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
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // ARSession Config
    private let session = ARSession()
    private let sessionConfiguration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        return config
    }()
    
    private var planeAnchor: ARAnchor?
    
    // Corner Detection variables
//    var counter = 0
//    let ciContext = CIContext.init(options: nil)
//    var camera: Camera?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session = session
        session.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            session.run(sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        } else {
            print("Sorry, your device doesn't support ARKit")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
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
}

// Mark: - ARSessionDelegate
extension ViewController: ARSessionDelegate{
    
    
// Corner detection code
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        let pixelBuffer = frame.capturedImage
//        guard let cgImage = ciContext.createCGImage(CIImage(cvPixelBuffer: pixelBuffer), from: CGRect(x:0, y:0, width:CVPixelBufferGetWidth(pixelBuffer),  height:CVPixelBufferGetHeight(pixelBuffer))) else { return }
//        detectCorners(in: cgImage)
//    }
    
//    func detectCorners(in cgImage: CGImage){
//        counter += 1
//        if counter != 10 { return }
//
//        let uiImage = UIImage(cgImage: cgImage)
//        let pictureInput = PictureInput(image: uiImage)
//        pictureInput.removeAllTargets()
//
//        // Harris Corner Detection Filter
//        let filter = HarrisCornerDetector()
//        filter.cornersDetectedCallback = { (positions) -> Void in
//            print("positions: \(positions)")
//        }
//
//        pictureInput.addTarget(filter)
//        pictureInput.processImage(synchronously: true)
//        counter = 0
//    }
}
