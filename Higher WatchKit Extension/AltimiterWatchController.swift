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
    var lastUpdateRecieved : NSDate?
    var userStopped = false
    var isPaused = false
    var submitedAction = false
    var lastImageName = "graph000"
    var inForeground = false
    @IBOutlet weak var currentAltitudeLabel: WKInterfaceLabel!
    
    
    @IBOutlet weak var timer: WKInterfaceTimer?
    @IBOutlet weak var group: WKInterfaceGroup!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        updateFromApp(true,isMainUpdateThread: true)
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
        inForeground = true
        updateFromApp(true,isMainUpdateThread: false)
        self.didReciveData()
    }
    
    override func didDeactivate() {
       inForeground = false
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
        if(replyInfo != nil){
            
      
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
        
            
        
        self.lastUpdateRecieved = replyInfo["lastUpdateRecieved"] as? NSDate
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(replyInfo["remaining"] , forKey: "remaining")
            prefs.setObject(replyInfo["climbed"] , forKey: "climbed")

        
        self.didReciveData()
        }else if error != nil{
            currentAltitude = "Error"
        }
    
        

    }
    
    
    
    
    func updateFromApp(scheduleUpdates: Bool, isMainUpdateThread:Bool){
        if(!submitedAction){
            WKInterfaceController.openParentApplication(["action": "refreshData"],
                reply: { (replyInfo, error) -> Void in
                    self.handleReply(replyInfo, error: error)
                    
                    
            })
        }
        
        if(scheduleUpdates){
            
            if isMainUpdateThread || inForeground {
                let seconds = isMainUpdateThread ? 60 : 1 as Double
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                    Int64(seconds * Double(NSEC_PER_SEC)))
                
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    self.updateFromApp(true,isMainUpdateThread: isMainUpdateThread)
                }
            }
            
        }
        
        
        
    }

    
    func didReciveData(){
                  handlePaused()
        if(!isPaused){
            let secondsSinceUpdate = lastUpdateRecieved != nil ? -lastUpdateRecieved!.timeIntervalSinceNow : 10000 as NSNumber
            println ("seconds since update = \(secondsSinceUpdate)")
            if secondsSinceUpdate.floatValue > (60 * 5) {
                currentAltitudeLabel.setText("Updating")
            }else if(currentAltitudeLabel != nil){
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