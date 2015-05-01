//
//  GPSAltimiter.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/29/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import CoreLocation
import CoreLocation
import CoreMotion
import UIKit

class GPSAltimiter: NSObject, CLLocationManagerDelegate{
    private let altimiter : Altimiter!
    let prefs = PreferenceHelper.getUserDefaults()
    var hasUpdatedPrefs = false
    private let locationManager = CLLocationManager()
    private let useBarometer : Bool =  CMAltimeter.isRelativeAltitudeAvailable()
     private var calibrationData : [(alititude: Double, accuracy : Int)] = []
    private var recalibrationStart  = NSDate()
    init(altimiter : Altimiter){
        super.init()
        self.altimiter = altimiter
        locationManager.delegate = self
    }
    
    func stopUpdates(){
         locationManager.stopUpdatingLocation()
    }
    
    func startUpdates(){
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()
    }
    
    func calibrateAndStart(){
        locationManager.requestAlwaysAuthorization()
        startUpdates()
        calibrationData = []
    }
    
    
    /***  --------------- Location GPS Related Methods ----------------*****/
    
    /***  Implementation of location manager delegate  ****/
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            println("Authorization status changed to \(status.rawValue)")
            switch status {
            case CLAuthorizationStatus.AuthorizedAlways:
                locationManager.startUpdatingLocation()
            case .AuthorizedWhenInUse :
                altimiter.delegate?.didStatusChange("Altimiter can only be calibrated manually. Please authorize background updates to allow infrequent access to location", isError: false)
                locationManager.startUpdatingLocation()
            default:
                locationManager.stopUpdatingLocation()
                altimiter.delegate?.didStatusChange("Altimiteter cannot be calibrated because location services are not enabled", isError: true)
                
            }
    }
    
    
    
    func locationManager(manager: CLLocationManager!,
        didFailWithError error: NSError!) {
            println ("recover=\(error.localizedRecoverySuggestion)")
            println ("failure reasion= \(error.localizedFailureReason)")
            var description = "Unable to determine location which is needed for calibration."
            if error != nil {
                switch error.code {
                case CLError.Denied.rawValue :
                    description += " Please make sure you have granted location services permission to this applicaiton by visiting the settings page"
                case CLError.LocationUnknown.rawValue :
                    description += " Please make sure that location services are turned on, and airplane mode is not enabled"
                default :
                    description +=  "Unknown error occured"
                }
                CLError.LocationUnknown
            }
            
            altimiter.delegate?.didStatusChange(description, isError: true)
            
    }
    
    
    
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        //background mode is only used to get barometer updates
        if ( locations == nil || (altimiter.inBackground && useBarometer)){
            return
        }
        let newLocation = (locations as [CLLocation])[locations.count - 1]
        if(!hasUpdatedPrefs){
            hasUpdatedPrefs = true
            PreferenceHelper.updateLocationBasedPrefs(newLocation)
        }
        let accuracy = lround(newLocation.verticalAccuracy)
        let altitude = newLocation.altitude
        
        if(useBarometer){
            if(!altimiter.calibrationPerformed){
                doCalibrateFromGPS(accuracy, altitude: altitude)
            }
        }else{
            doUpdateAltitudeFromGPS(accuracy, altitude: altitude)
        }
        
    }
    
    //** If the hardware does not support barometric updates this sets the alititude from gps data
    private func doUpdateAltitudeFromGPS(accuracy: Int, altitude:Double){
        if altimiter.calibrationPerformed  {
            if(accuracy > 0 && accuracy < 50){
                altimiter.setNewAltititude(altitude)
            }
        }else{
            if(accuracy > 0 && accuracy < 10){
              calibrationData.append (alititude: altitude, accuracy : accuracy)
                setCalibratedAltitudeFromData()
                altimiter.startAltitude = altimiter.calibratedAltitude
            }else{
                altimiter.delegate?.didStatusChange("Determining altitude \(formatForDisplay(altitude)) +- \(formatForDisplay(accuracy,roundToTens: false))", isError: false)

            }
        }
        
    }

    private func doCalibrateFromGPS(accuracy : Int, altitude : Double){
        let timeElapsedInSeconds = -altimiter.startTime.timeIntervalSinceNow
        
        if accuracy < 0 || accuracy > 50 {
            if   timeElapsedInSeconds > 30 {
                locationManager.stopUpdatingLocation()
                altimiter.delegate?.didStatusChange("Failed to determine accurate altitude from gps. Please make sure you are outside in a clear area and try again", isError: true)
            }else{
                altimiter.delegate?.didStatusChange("Determining altitude \(formatForDisplay(altitude)) +- \(formatForDisplay(accuracy,roundToTens: false))", isError: false)
                return
            }
            
        }else if calibrationData.count > 5 || timeElapsedInSeconds > 30 {
            println ("calibrated with accuracy \(accuracy)" )
            if(calibrationData.count == 0){
                calibrationData.append (alititude: altitude, accuracy : accuracy)
            }
            setCalibratedAltitudeFromData()
            altimiter.startAltitude = altimiter.calibratedAltitude
            altimiter.delegate?.didStatusChange("Calibrated with accuracy +- \(formatForDisplay(accuracy,roundToTens: false))", isError: false)
            setRecalbrateTask()
            altimiter.statusChanged()
            
        }else if accuracy <= 5 {
            altimiter.currentAltititude = altitude
            calibrationData.append (alititude: altitude, accuracy : accuracy)
            altimiter.delegate?.didStatusChange("Determining altitude \(formatForDisplay(altitude)) +- \(altimiter.formatForDisplay(accuracy,roundToTens: false))", isError: false)
        }else{
            altimiter.currentAltititude = altitude
            altimiter.delegate?.didStatusChange("Determining altitude \(formatForDisplay(altitude)) +- \(altimiter.formatForDisplay(accuracy,roundToTens: false))", isError: false)
        }
        
    }
    
    private func formatForDisplay(altitude :NSNumber, roundToTens: Bool=true) -> String {
       return altimiter.formatForDisplay(altitude, roundToTens: roundToTens)
    }
    
    private func doReCalibrateFromGPS(accuracy : Int, altitude : Double){
        let timeElapsedInSeconds = -recalibrationStart.timeIntervalSinceNow
        println ("re calibrating from gps")
        if accuracy < 0 || accuracy > 50 {
            if   timeElapsedInSeconds > 30 {
                locationManager.stopUpdatingLocation()
                setRecalbrateTask()
            }
            
        }else if calibrationData.count > 10 || timeElapsedInSeconds > 30 {
            setCalibratedAltitudeFromData()
            println ("recalibrated with accuracy \(accuracy)" )
            
            altimiter.delegate?.didStatusChange("Recalibrated with accuracy +- \(altimiter.formatForDisplay(accuracy,roundToTens: false))", isError: false)
            setRecalbrateTask()
            altimiter.statusChanged()
            
            
        }
        else if accuracy <= 5 {
            calibrationData.append (alititude: altitude, accuracy : accuracy)
        }else{
            altimiter.delegate?.didStatusChange("Determining altitude \(altimiter.formatForDisplay(altitude)) +- \(altimiter.formatForDisplay(accuracy,roundToTens: false))", isError: false)
        }
        
    }
    
    /** This function recalibrates the current alititude by initiating background location updates **/
    func reCalibrate(){
        if(useBarometer && !altimiter.userStoped){
            recalibrationStart = NSDate()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    /** sets a background taskto peridocally recalibrate from gps **/
    //todo this doesn't fire properly when app is backgrounded not sure this is a useful feature.
    private func setRecalbrateTask(){
        if(!altimiter.inBackground){
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(3600 * Double(NSEC_PER_SEC)))
            let selfRef = self
            dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0)) {
                selfRef.reCalibrate()
            }
        }
        
    }
    
    private func setCalibratedAltitudeFromData(){
        altimiter.calibrationPerformed = true
        var sum : Double = 0
        for data in calibrationData {
            sum += data.alititude
        }
        let avg = sum / Double(calibrationData.count)
        altimiter.calibratedAltitude = avg
        altimiter.currentAltititude = avg
        altimiter.rollingAsscentRate.altitude = avg
        altimiter.rollingAsscentRate.timeStamp = NSDate()
        calibrationData = []
        if(useBarometer){
           altimiter.startUpdatesFromBarometer()
           locationManager.stopUpdatingLocation()
        }
        
        
        
    }


}