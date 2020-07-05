//
//  Constants.swift
//  StitchBuddy
//
//  Created by Miles Au on 2020-07-03.
//  Copyright © 2020 Miles Au. All rights reserved.
//

import Foundation
import UIKit

class ARConstants {
    static let defaultHeight = CGFloat(0.0001)
    static let lineWidth = CGFloat(0.002)
    
    static let actionColor = UIColor.systemYellow
    static let leftColor = UIColor.systemBlue;
    static let rightColor = UIColor.systemPurple;
    
    enum Interactive: Int {
        case no = 1
        case yes = 2
    }
}
