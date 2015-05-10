//
//  PreferenceHelper.swift
//  AltimiterPlay
//
//  Created by Ganger, Keith E on 4/15/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
class PreferenceHelper: NSObject, CLLocationManagerDelegate{
    class func getUserDefaults()->NSUserDefaults{
        let prefs = NSUserDefaults.standardUserDefaults()
        let defaults = [
            "useMetric":false,
            "state":"",
            "hasSetLocation":false,
            "recalibrateOnResume":false,
            
        ]
        prefs.registerDefaults(defaults)
        
        
        return prefs
    }
    
    
    
    
    
    class func updateLocationBasedPrefs(location : CLLocation){
        let prefs  = PreferenceHelper.getUserDefaults()
        if(!prefs.boolForKey("hasSetLocation")){
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
  
                if error != nil {
                    println("Reverse geocoder failed with error" + error.localizedDescription)
                    return
                }
                
                if placemarks.count > 0 {
                    let pm:CLPlacemark = placemarks[0] as CLPlacemark
                    if(pm.ISOcountryCode == "US"){
                        prefs.setBool(false, forKey: "useMetric")
                        prefs.setObject(pm.administrativeArea, forKey: "state")
                    }else{
                       prefs.setBool(true, forKey: "useMetric")
                    }
                    prefs.setBool(true, forKey: "hasSetLocation")
                    prefs.synchronize()
                }
                else {
                    println("Problem with the data received from geocoder")
                }
            })
            
        }
        
    }
}


