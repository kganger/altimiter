//
//  SetDestinationController.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/30/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import WatchKit
class RemainingController : WKInterfaceController {

    
    @IBOutlet weak var remainingLabel: WKInterfaceLabel!
    
    
    @IBOutlet weak var climbedLabel: WKInterfaceLabel!
    var mainController : AltimiterWatchController!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        if(context != nil){
            mainController = context as AltimiterWatchController
            remainingLabel.setText(mainController.remaining)
            climbedLabel.setText(mainController.climbed)
        }

        // Configure interface objects here.
    }
    
    
}