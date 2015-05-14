//
//  AltimiterWatchHelper.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/28/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import WatchKit

class AltimiterWatchController : WKInterfaceController {
    var currentAltitude = ""
    var startTime : NSDate?
    var percentComplete : NSNumber = 0
    var destinationAltitude : NSNumber = 0
    var climbed = ""
    var remaining = ""
    var userStopped = false
    var isPaused = false
    var submitedAction = false
    var lastImageName = "graph000"
    @IBOutlet weak var currentAltitudeLabel: WKInterfaceLabel!
    
    
    @IBOutlet weak var timer: WKInterfaceTimer?
    @IBOutlet weak var group: WKInterfaceGroup!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        updateFromApp()
    }
    
    func updateBackground(){
        if group != nil {
            let number = lroundf(percentComplete.floatValue * 100)
            if (destinationAltitude.floatValue > 0 && number > 0 && number <= 100){
                let formatter = NSNumberFormatter()
                
                formatter.numberStyle = NSNumberFormatterStyle.NoStyle
                formatter.roundingIncrement = 0
                formatter.minimumIntegerDigits = 3
                var numberString = formatter.stringFromNumber(number)
                if(numberString != nil){
                    lastImageName = "graph\(numberString!)"
                    println ("setting background to '\(lastImageName)'")
                    group.setBackgroundImageNamed(lastImageName)
                }
            }
        }
        
    }
    
     override func willActivate() {
        super.willActivate()
        self.didReciveData()
    }
    
    func didPause(){
        group.setBackgroundImageNamed("paused")
        currentAltitudeLabel.setHidden(true)
        isPaused = true
        if(timer != nil){
            timer?.stop()
        }
        
    }
    
    func didResume(){
        group.setBackgroundImageNamed(lastImageName)
        currentAltitudeLabel.setHidden(false)
        if(timer != nil){
            timer?.start()
        }
        isPaused = false
        
        
    }
    
    func handlePaused() {
        if(userStopped && !isPaused){
            didPause()
        }else{
            if(isPaused && !userStopped){
                didResume()
            }
            
        }
        
    }
    
    func stop(){
        userStopped = true
        submitedAction = true
        handlePaused()
        WKInterfaceController.openParentApplication(["action": "stop"],
            reply: { (replyInfo, error) -> Void in
                
                self.handleReply(replyInfo, error: error)
                self.submitedAction=false
        })
 
    }
    
    func start(){
        submitedAction = true
        WKInterfaceController.openParentApplication(["action": "start"],
            reply: { (replyInfo, error) -> Void in
                
                self.handleReply(replyInfo, error: error)
                self.submitedAction = false
                
        })

    }
    
  
    
    func handleReply(replyInfo: [NSObject : AnyObject]!, error: NSError!){
        if(replyInfo["percentComplete"] != nil){
            self.percentComplete = replyInfo["percentComplete"]! as NSNumber
        }
        if(replyInfo["currentAltitude"] != nil){
            self.currentAltitude = replyInfo["currentAltitude"]! as NSString
        }
        
        if(replyInfo["destinationAltitude"] != nil){
            self.destinationAltitude = replyInfo["destinationAltitude"]! as NSNumber
        }
        
        if(replyInfo["startTime"] != nil){
            self.startTime = replyInfo["startTime"] as? NSDate
        }
        
        if(replyInfo["userStoped"] != nil){
            self.userStopped = replyInfo["userStoped"]! as Bool
        }
        
        if(replyInfo["remaining"]  != nil){
            self.remaining = replyInfo["remaining"]! as NSString
        }
        
        if(replyInfo["climbed"] != nil){
            self.climbed = replyInfo["climbed"]! as NSString
        }


        
        
        self.didReciveData()
        //handle update in main queue
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(5 * Double(NSEC_PER_SEC)))

        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.updateFromApp()
        }
        

    }
    
    
    
    
    func updateFromApp(){
        if(!submitedAction){
            WKInterfaceController.openParentApplication(["action": "refreshData"],
                reply: { (replyInfo, error) -> Void in
                    self.handleReply(replyInfo, error: error)
                    
                    
            })
        }
        
        
        
    }

    
    func didReciveData(){
                  handlePaused()
        if(!isPaused){
            if(currentAltitudeLabel != nil){
                currentAltitudeLabel.setText(currentAltitude)
            }
                      updateBackground()
            if(startTime != nil && timer != nil  ){
                timer?.setDate(startTime!)
                timer?.start()
            }


        }
        
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject?{
        return self
    }
    
    
}