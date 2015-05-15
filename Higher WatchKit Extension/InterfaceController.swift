//
//  InterfaceController.swift
//  Higher WatchKit Extension
//
//  Created by Ganger, Keith E on 4/27/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import WatchKit
import Foundation
import HikingAltimiter


class InterfaceController: AltimiterWatchController {
  


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
                                         // Configure interface objects here.
    
    }
       
    @IBAction func doSetDestination(){
        println ("setting destintation")
        presentControllerWithName("setDestination", context: self)
    }
    
    @IBAction func doStart(){
        start()
    }
    
    @IBAction func doStop(){
        stop()
    }
    
    


    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
     override func didReciveData() {
        super.didReciveData()
          }

}
