//
//  SavedPointHelper.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/20/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SavedPointHelper{
    
    private let appDelegate : AppDelegate!
    private let context : NSManagedObjectContext!
    private let entityName : String = "SavedPlace"
    let placeFiles = ["CO":"colorado"]
    var places : [SavedPlace] = []
    init(){
        appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        context = appDelegate.managedObjectContext
        let app = UIApplication.sharedApplication()
        
        loadList()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationWillResignActive:",
            name: UIApplicationWillResignActiveNotification,
            object: app)
        
        
    }
    
    
    
    func loadList(){
        let request = NSFetchRequest(entityName: entityName)
        var error:NSError? = nil
        
        let objects = context?.executeFetchRequest(request, error: &error)
        if let objectList = objects {
            for oneObject in objectList {
                let altitude = oneObject.valueForKey("elevation")!.floatValue
                let name = oneObject.valueForKey("name") as String
                places.append(SavedPlace(name:name,altitude:altitude))
            }
        } else {
            println("There was an error")
            // Do whatever error handling is appropriate
        }
        
        println("Loaded \(places.count) places")
        
        
    }
    
    func doImport(stateKey:String){
        let bundle = NSBundle.mainBundle()
        let file = placeFiles[stateKey]
        if file != nil{
            let path = bundle.pathForResource(file!, ofType: "gpx")
            if(path != nil){
                let parser = GPXParser()
                parser.parseGPX(NSURL(fileURLWithPath: path!)!)
                var error:NSError? = nil
                let request = NSFetchRequest(entityName: entityName)
                for waypoint in parser.wayPoints{
                    var obj = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context!) as NSManagedObject
                    obj.setValue(waypoint.name, forKey: "name")
                    obj.setValue(waypoint.elevation, forKey: "elevation")
                    
                }
                appDelegate.saveContext()
                loadList()
            }else{
                let file = placeFiles["CO"]
                println ("didnt find a file for \(file)")
            }
  
        }else{
            println ("No place file fouund for \(stateKey)")
        }
        
        // for
        
    }
}
class SavedPlace{
    let name : String!
    let altitude : NSNumber!
    
    init(name: String, altitude:NSNumber){
        self.name = name
        self.altitude = altitude
    }
}
