//
//  gpx.swift
//  gpxImporttest
//
//  Created by Ganger, Keith E on 4/9/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation


class GPXParser : NSObject, NSXMLParserDelegate{
    var parser = NSXMLParser()
    let url = NSURL(fileURLWithPath: "/Users/kganger/Documents/mountainApp/13ers.gpx")
    var currentElement = NSString()
    var inWaypoint = false
    var elements = NSMutableDictionary()
    var wayPoints = [GPXWaypoint]()
    var wpt: GPXWaypoint!
    var currentData : NSString = ""
    
    override init(){
        
    }
    func parseGPX(url: NSURL){
        
        parser = NSXMLParser(contentsOfURL: url)!
        parser.delegate=self
        parser.parse()
        wayPoints.sort{$0.name < $1.name }
    }
    

    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        currentElement = elementName
        currentData = ""
        if(elementName as NSString).isEqualToString("wpt"){
            if( attributeDict["lat"] != nil && attributeDict["lon"] != nil){
            let latString =  attributeDict["lat"] as NSString
            let longString = attributeDict["lon"] as NSString
                wpt = GPXWaypoint(latitude: latString.floatValue, longitude: longString.floatValue)
                inWaypoint = true
            }
        }
        
    }
    
     func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if inWaypoint && wpt != nil{
          currentData = currentData + string
        }
    }
    
     func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        let name = elementName as NSString
        if name.isEqualToString("wpt"){
            wayPoints.append(wpt)
            inWaypoint = false
        }else if name.isEqualToString("ele"){
            wpt.elevation = currentData.floatValue
        } else if name.isEqualToString("name") {
            wpt.name = currentData
        }else if name.isEqualToString("cmt") {
            wpt.comment = currentData
        }else if name.isEqualToString("desc") {
            wpt.description = currentData
        }else if name.isEqualToString("link") {
            wpt.link = currentData
        }else{
            //println ( "\(currentElement) = \(string)")
        }

        

    
    }
}

class GPXWaypoint{
    var elevation : Float = 0.0
    var name : String = ""
    var comment : String = ""
    var description : String = ""
    var latitude : Float
    var longitude : Float
    var link : String = ""
    var type : String = ""
    
    func appendName(string:NSString){
        name += string
    }
    
    init(latitude: Float, longitude: Float){
              self.longitude = longitude
        self.latitude = latitude
    }
    
    func toString()->NSString{
      return "\(name) - \(latitude) : \(longitude) "
    }
}