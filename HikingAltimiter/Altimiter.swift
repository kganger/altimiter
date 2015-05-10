//
//  Altimiter.swift
//  AltimiterPlay
//
//  Created by Ganger, Keith E on 4/14/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit


class Altimiter: NSObject, CLLocationManagerDelegate{
    
    
    var startTime : NSDate = NSDate()
    var calibratedAltitude :Double = -100000
    var startAltitude : Double = -10000
    var currentAltititude : Double = -100000
    var alititudeChange : Int = 0
    var totalGain : NSNumber = 0
    var destinationAltitude : Double = 1500
    let altimeter = CMAltimeter()
    let prefs = PreferenceHelper.getUserDefaults()
    var delegate : AltimiterDelegate?
    let useBarometer : Bool!
    let gps : GPSAltimiter!
    
    var userStoped = false
    private var altimiterRunning = false
    var calibrationPerformed = false
    var inBackground = false
    var altitudeUpdateRecieved = false
    private var backgroundedTime = NSDate()
    let lock = NSCondition()
    
   
    
    
    var rollingAsscentRate = (timeStamp:NSDate(),altitude:NSNumber (double: 0.0))
    
    
    
    override init(){
        super.init()
        useBarometer = CMAltimeter.isRelativeAltitudeAvailable() && prefs.boolForKey("useBarometer")
        gps =  GPSAltimiter(altimiter:self)
    }
    
    func getCurrentAltitudeSynchcronsously()->Double{
       altitudeUpdateRecieved = false
//        while !altitudeUpdateRecieved {
//            lock.wait()
//        }
          return currentAltititude
    }
    
 
    func setDelegate(delegate: AltimiterDelegate){
        self.delegate = delegate
    }
    
    func enterBackgroundMode(){
       inBackground = true
        backgroundedTime = NSDate()
        if(!useBarometer){
            gps.stopUpdates()
        }
    }
    
    func enterForegroundMode(){
          statusChanged()
        if(!useBarometer){
          gps.startUpdates()
        }else if (-backgroundedTime.timeIntervalSinceNow > 120) && prefs.boolForKey("recalibrateOnResume"){
            gps.reCalibrate()
        }
      
        
        inBackground = false
        

    }
   
    func startIfNotRunning(){
         lock.lock()
        if(!altimiterRunning && !userStoped){
            lock.unlock()
             //if there was an autosave from today then restart
             let lastAutoSaveStart = prefs.objectForKey("startTime") as NSDate?
            if lastAutoSaveStart != nil && (-lastAutoSaveStart!.timeIntervalSinceNow  < 86400){
               resumeFromSave()
            }else{
                calibrateAndStart()
            }
          
        }
        lock.unlock()
        
    }
    
    private func resumeFromSave(){
        if(prefs.objectForKey("startTime") != nil){
            startTime = prefs.objectForKey("startTime") as NSDate!
        }else{
            startTime = NSDate()
        }
        if(prefs.objectForKey("destinationAltitude") != nil){
            destinationAltitude = prefs.doubleForKey("destinationAltitude")
        }
        if(prefs.objectForKey("startAltitude") != nil){
            startAltitude = prefs.doubleForKey("startAltitude")
            doCommonCalibration()
            calibrationPerformed = true
            gps.reCalibrate()
        }else{
            calibrateAndStart()
            return
        }

    }
    
     func autoSave(){
       prefs.setObject(startTime, forKey: "startTime")
       prefs.setDouble(startAltitude, forKey: "startAltitude")
       prefs.setDouble(destinationAltitude, forKey: "destinationAltitude")
       prefs.synchronize()
    }
    

    
    
    private func doCommonCalibration(){
        altimiterRunning = true
        
        alititudeChange = 0
        totalGain = 0
        currentAltititude = 0
        
        userStoped = false
        rollingAsscentRate = (NSDate(),0.0)
        if UIDevice.currentDevice().model == "iPhone Simulator" {
            simulateAltitude()
        }
    }
    
    func calibrateAndStart(){
        stopTracking()
        lock.lock()
        doCommonCalibration()
        calibrationPerformed = false
        startTime = NSDate()
        calibratedAltitude = 0
        gps.calibrateAndStart()
        lock.unlock()

        
    }
    
    
    func setDestination(altitude : NSNumber){
        destinationAltitude = prefs.boolForKey("useMetric") ? altitude.doubleValue : altitude.doubleValue / 3.28084
        delegate?.didDestinationAltitudeChange(self)
        delegate?.didStatusChange("Destination altitude set to \(formatForDisplay(destinationAltitude, roundToTens: false))", isError: false)
    }
    
    func stopTracking(){
        lock.lock()
        if(!userStoped){
            altimeter.stopRelativeAltitudeUpdates()
            gps.stopUpdates()
            userStoped = true
            calibrationPerformed=false
            delegate?.didStatusChange("Altitude Tracking Stopped", isError: false)
        }
        lock.unlock()

    }
    
    func formatForDisplay(altitude :NSNumber, roundToTens: Bool=true) -> String{
        
        if !prefs.boolForKey("useMetric"){
            let altInFt = altitude.doubleValue * 3.28084
            let roundedAlt = roundToTens ? getRoundedAltitude(altInFt) : lround(altInFt)
            return "\(roundedAlt) FT"
            
        }else{
            return "\(roundToTens ? getRoundedAltitude(altitude.doubleValue) : altitude) M"
        }
        
        
    }
    
    func adjustForMetric(number: NSNumber) -> NSNumber{
          if !prefs.boolForKey("useMetric"){
            return number.doubleValue * 3.28084
          }else{
            return number
        }
    }
    
    func getRoundedAltitude(myAltitude: Double)->Int{
        return lround(10 * round(myAltitude / 10))
        
    }
    private func calcAscentRate(date :NSDate, change:NSNumber)->Int{
        let timeElapsed = -date.timeIntervalSinceNow
            let rate : NSNumber = ((change.doubleValue / timeElapsed) * 3600)
        return rate.integerValue
    }
    
    func getAssentRate() ->(current:Int, overall:Int){
        let overall = calcAscentRate(startTime, change: alititudeChange)
       
        if(-rollingAsscentRate.timeStamp.timeIntervalSinceNow > (20 * 60)){
            rollingAsscentRate = (altitude:currentAltititude,NSDate())
            println ("reset rolling asscent rate \(currentAltititude)")
        }
        let currentChange = currentAltititude - rollingAsscentRate.altitude.doubleValue
       // println ("calculating current rate change=\(currentChange) inteval - \(rollingAsscentRate.timeStamp.timeIntervalSinceNow)")
        let current = calcAscentRate(rollingAsscentRate.timeStamp, change: currentChange)

        return (current,overall)
    }
    
    func getPercentComplete()->NSNumber{
        var percentComplete:NSNumber = 0.0
        if destinationAltitude > 0  && calibrationPerformed {
             let remaining : NSNumber = destinationAltitude - currentAltititude
             let total : NSNumber = destinationAltitude - startAltitude
             percentComplete = 1 - (remaining.floatValue / total.floatValue)
            
           // println ( "calculated percent complete \(remaining.floatValue) / \(total.floatValue) = \(percentComplete.floatValue)")
        }
        return percentComplete
    }
    
    func getFinishTime()->String{
        let remaining : NSNumber = destinationAltitude - currentAltititude
        let rate : NSNumber = Float(getAssentRate().overall) / (60 * 60)
        let remainingSeconds : NSNumber = remaining.floatValue / rate.floatValue
        let userCalendar = NSCalendar.currentCalendar()
        let futureDate = userCalendar.dateByAddingUnit(NSCalendarUnit.SecondCalendarUnit, value:remainingSeconds.integerValue, toDate: NSDate(),options: NSCalendarOptions.MatchNextTime)
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.NoStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(futureDate!)
    }
    
    func getElapsedTime()->String{
        var elapsedTime = -startTime.timeIntervalSinceNow
        var seconds = lround(elapsedTime)
        var minutes : Int = lround(Double (seconds / 60))
        var hours  = lround(Double (minutes / 60))
        
        let startDate  = NSDate()
        let formatter = NSNumberFormatter()
        
        formatter.numberStyle = NSNumberFormatterStyle.NoStyle
        formatter.roundingIncrement = 0
        formatter.minimumIntegerDigits = 2
        
        
        if hours >= 1{
            minutes  = minutes % 60
            seconds = seconds % 60
        }else if( minutes >= 1){
            seconds = seconds % 60
            hours = 0
        }else{
            minutes = 0
            hours = 0
        }
        
        var timeString = formatter.stringFromNumber(hours)! + ":" +
            formatter.stringFromNumber(minutes)! + ":" +
            formatter.stringFromNumber(seconds)!
        return timeString
    }
    
    func setRelativeAltitude(relativeAltitude : NSNumber){
      
        let newAltitude = calibratedAltitude + relativeAltitude.doubleValue
        let change :NSNumber = newAltitude - currentAltititude
        if change.integerValue > 0{
            totalGain = change.integerValue + totalGain.integerValue as NSNumber
        }
        setNewAltititude(newAltitude)
        println ("setting relative altitude current=\(currentAltititude) relative=\(relativeAltitude.stringValue)")
        
    }
    
    func setNewAltititude(newAltitude : Double){
        currentAltititude = newAltitude
        alititudeChange = lround(currentAltititude - startAltitude)
        statusChanged()
    }
    
     func startUpdatesFromBarometer(){
        let altimiterRef = self
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (altitudeData: CMAltitudeData!, error: NSError!) in
                altimiterRef.setRelativeAltitude(altitudeData.relativeAltitude)
            }
        }
    }
    
   
   
    
    private func simulateAltitude(){
        startAltitude=1500
        calibratedAltitude = 1500
        currentAltititude = calibratedAltitude
        rollingAsscentRate.altitude = calibratedAltitude
        rollingAsscentRate.timeStamp = NSDate()
        calibrationPerformed=true
        doSimulatedUpdate(0)
        
        
    }
    private func doSimulatedUpdate(lastValue: NSNumber){
        let selfRef = self
        let nextVal : NSNumber = lastValue.floatValue + 0.7
        setRelativeAltitude(nextVal)
        let percent = getPercentComplete()
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(1 * Double(NSEC_PER_SEC)))
        //handle update in main queue
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if !selfRef.userStoped {
                selfRef.doSimulatedUpdate(nextVal)
            }
            
        }
        
    }


     func statusChanged(){
        if(delegate != nil){
            delegate?.didAltitudeChange(self)
        }
//        lock.lock()
//        altitudeUpdateRecieved = true
//        lock.broadcast()
//        lock.unlock()
    }
}

class AltitudePoint {
    let altitude : Float
    let timeStamp : NSDate
    
    init(altitude: Float){
        self.altitude=altitude
        self.timeStamp = NSDate()
    }
}
