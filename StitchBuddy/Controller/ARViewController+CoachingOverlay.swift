//
//  ARViewController+CoachingOverlay.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-04.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import ARKit

// MARK: - Coaching Overlay
extension ARViewController: ARCoachingOverlayViewDelegate{
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
        actionsView.isHidden = false
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        updateIsPlacingCorner(to: false)
    }

}
