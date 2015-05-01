//
//  PlacesTableView.swift
//  HikingAltimiter
//
//  Created by Ganger, Keith E on 4/20/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import Foundation
import UIKit
class PlacesTableView: UITableViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate{
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    @IBOutlet weak var placesView: UITableView!
    let cellTableIdentifier = "CellTableIdentifier"
    var wayPoints = [GPXWaypoint]()
    var filteredWapoints = [GPXWaypoint]()
    var altimiter:Altimiter = Altimiter()
      let prefs = PreferenceHelper.getUserDefaults()
    
    var indexList: [String:(count:Int,firstIndex:Int)] = [:]
    var sections: [String] = []
    //var altimiter : Altimiter = Altimiter()
    override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = NSBundle.mainBundle()
 
                   let  appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
            altimiter = appDelegate.altimiter
            wayPoints = appDelegate.getWaypoints()
        
        
        //  placesView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellTableIdentifier)
        
    }
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filteredWapoints = self.wayPoints.filter({( waypoint: GPXWaypoint) -> Bool in
            //  let categoryMatch = (scope == "All") || (candy.category == scope)
            let stringMatch = waypoint.name.rangeOfString(searchText)
            return  stringMatch != nil
        })
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
        return true
    }
    
   
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let optionalSection = indexList[sections[section]]
//        if(optionalSection != nil){
//            let mySeciton = optionalSection!
//            return mySeciton.count
//        }else{
//            return 0
//        }
        
        if tableView == self.searchDisplayController!.searchResultsTableView{
            return filteredWapoints.count
        }else{
            return wayPoints.count
        }
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        var rowData = wayPoints[indexPath.item]
        if tableView == self.searchDisplayController!.searchResultsTableView && filteredWapoints.count >= indexPath.item {
            rowData = filteredWapoints[indexPath.item]
        }
        let altitude = rowData.elevation as NSNumber
        altimiter.setDestination(altitude)
       
        if let navigationController = self.navigationController
        {
            navigationController.popViewControllerAnimated(true)
        }
        self.dismissViewControllerAnimated(false, completion: nil)
        //selected
    }
    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return self.indexList.count
//    }
//    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sections[section]
//    }
    
    
   
    
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell {
            var cell : UITableViewCell?
            cell = (placesView.dequeueReusableCellWithIdentifier(cellTableIdentifier, forIndexPath: indexPath)
                as UITableViewCell)
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle,reuseIdentifier:cellTableIdentifier)
            }
            var rowData = wayPoints[indexPath.item]
        if tableView == self.searchDisplayController!.searchResultsTableView && filteredWapoints.count >= indexPath.item {
                rowData = filteredWapoints[indexPath.item]
            }
            cell?.textLabel?.text = rowData.name
            cell?.detailTextLabel?.text = "\(lroundf(rowData.elevation)) FT"
            
            return cell!
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
}
