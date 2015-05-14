//
//  SetDestinationController.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/30/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import WatchKit
class SetDestinationController : WKInterfaceController {
    
    private var selectedValue : NSNumber = 0

    var mainController : AltimiterWatchController!
        @IBOutlet weak var slider: WKInterfaceSlider!
    
    @IBOutlet weak var destinationLabel: WKInterfaceLabel!
    
    @IBAction func sliderChanged(value: Float) {
        destinationLabel.setText("\(lroundf(value))")
        self.selectedValue = value as NSNumber
    }
    
    @IBAction func saveDestination() {
        WKInterfaceController.openParentApplication(["action": "setDestination","destination": selectedValue],
            reply: { (replyInfo, error) -> Void in
                self.mainController.handleReply(replyInfo, error: error)
        })

   
        dismissController()
    }
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        mainController = context as
        AltimiterWatchController
        
        var destNumber : NSNumber = (mainController.currentAltitude as NSString).integerValue
        if(mainController.destinationAltitude.integerValue > 0 ){
            destNumber = mainController.destinationAltitude
            
        }
        //round to the nearest 250 ft
        let rounded=round(destNumber.floatValue / 250.0)
        destNumber = lroundf(250.0 * rounded) as NSNumber
         selectedValue = destNumber
        destinationLabel.setText(destNumber.stringValue)
        slider.setValue(destNumber.floatValue)
        // Configure interface objects here.
    }
    
    
}