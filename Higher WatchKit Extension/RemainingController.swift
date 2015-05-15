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
    var inForeground = true
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        

        // Configure interface objects here.
    }
    
    override func willActivate() {
        inForeground = true
        doUpdates()
    }
    
    override func didDeactivate() {
        inForeground = false
    }
    
    func doUpdates(){
        let prefs = NSUserDefaults.standardUserDefaults()
        if prefs.objectForKey("remaining") != nil && prefs.objectForKey("climbed") != nil &&
            inForeground {
            remainingLabel.setText(prefs.objectForKey("remaining") as? String)
            climbedLabel.setText(prefs.objectForKey("climbed") as? String)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(5 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.doUpdates()
            }
            
        }
    }
    
}