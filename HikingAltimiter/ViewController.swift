//
//  ViewController.swift
//  AltimiterPlay
//
//  Created by Ganger, Keith E on 4/14/15.
//  Copyright (c) 2015 Ganger, Keith E. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AltimiterDelegate{
    /******* Main View Outlets ************/
    
    @IBOutlet weak var selectDestinationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentAltitude: UILabel!
    
    @IBOutlet weak var destinationInput: UITextField!
    
    
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var currentAscentRateLabel: UILabel!
    
    @IBOutlet weak var startLabel: UILabel!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var altitudeChange: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var ascentRateLabel: UILabel!
    
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var finishTimeLabel: UILabel!
    
    @IBOutlet var roudableViews: [UIView]!
    
    //member variables
    private let  appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
    private var altimiter = Altimiter()
    private var statusHidden = false
    private let prefs =  PreferenceHelper.getUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set ability to hide keyboard on background tap
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard"))
        tapGesture.cancelsTouchesInView = true
        scrollView.addGestureRecognizer(tapGesture)
        
   
        altimiter = appDelegate.altimiter
        altimiter.setDelegate(self)
        
        if(!appDelegate.hasLocationDatabase){
            selectDestinationButton.enabled = false
        }
        selectDestinationButton.layer.cornerRadius = 5
        selectDestinationButton.clipsToBounds = true
        styleViews()
        statusHidden = statusLabel.hidden
               
    }
    

    
    
    
    
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func styleViews(){
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "metal_background")!)
        
        for roudableView in roudableViews {
            roudableView.layer.cornerRadius = 5
            roudableView.clipsToBounds = true
        }
        actionButton.layer.cornerRadius = 5
        actionButton.clipsToBounds = true
        
    }
    
    func hideKeyboard(){
        destinationInput.resignFirstResponder()
        let newDest = (destinationInput.text as NSString).integerValue
        if newDest > 0{
            altimiter.setDestination(newDest)
            destinationLabel.text = altimiter.formatForDisplay(altimiter.destinationAltitude)
        }
    }
    
    
    
    @IBAction func toggleTracking(sender: AnyObject) {
        if  altimiter.altimiterRunning {
            altimiter.stopTracking()
            hideStatusLabel()
        }else{
            hideKeyboard()
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            
            altimiter.calibrateAndStart()
        }
        updateTrackingButtons()
    }
    
    func updateTrackingButtons(){
        let title = altimiter.altimiterRunning ? "Stop Tracking" : "Start Tracking"
        println ("updating buttons \(altimiter.altimiterRunning) \(title)")
        actionButton.setTitle(title, forState: UIControlState.Normal)

    }
    
    class func getRemainingText(altimiter : Altimiter) -> String {
        if(altimiter.destinationAltitude < 0 ){
            return ""
        }
        var remaining : NSNumber = altimiter.destinationAltitude - altimiter.currentAltititude
        var remainingText : String = ""
        if remaining.integerValue > 0 {
            remainingText = "-\(altimiter.formatForDisplay(remaining))"
        }else{
            remainingText = "+\(altimiter.formatForDisplay(-remaining.doubleValue))"
        }
        return remainingText
    }
    
    
    /*** Altimiter delegate protocol implementation ***/
    
    func didAltitudeChange(altimiter:Altimiter){
        actionButton.enabled = true
        currentAltitude.text = altimiter.formatForDisplay(altimiter.currentAltititude)
        startLabel.text = altimiter.formatForDisplay(altimiter.startAltitude)
        
        var altitudeChangeText = altimiter.alititudeChange > 0 ? "+" : ""
        altitudeChangeText += "\(altimiter.formatForDisplay(altimiter.alititudeChange))"
        altitudeChange.text = altitudeChangeText
        
        if(altimiter.destinationAltitude > 0 ){
            
            destinationLabel.text = altimiter.formatForDisplay(altimiter.destinationAltitude)
            
            remainingLabel.text = "\(ViewController.getRemainingText(altimiter))"
            
            setFnishTime(altimiter)
            
        }
        let ascentRates = altimiter.getAssentRate()
        let rate = altimiter.formatForDisplay(ascentRates.overall, roundToTens: false)
        ascentRateLabel.text = "\(rate)PH"
        
        let currentRate = altimiter.formatForDisplay(ascentRates.current, roundToTens: false)
        currentAscentRateLabel.text = "\(currentRate)PH"
        
        timeElapsedLabel.text = altimiter.getElapsedTime()
        if !activityIndicator.hidden{
            activityIndicator.stopAnimating()
            
        }
        hideStatusLabel()
        
        updateProgress(altimiter)
        
    }
    
    func didStatusChange(status : String, isError: Bool){
        if isError{
            let alertController = UIAlertController(title: "Altimiter Error",
                message: status, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in })
            alertController.addAction(okAction)
            presentViewController(alertController, animated: true, completion: nil)
                        activityIndicator.hidden = true
            actionButton.enabled = true
            
            
        }else{
            statusLabel.text = status
            
            if(statusHidden || statusLabel.hidden){
                statusLabel.alpha = 0
                statusLabel.hidden = false
                statusHidden = false
                UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.statusLabel.alpha = 0.65
                    }, completion: nil)
            }
        }
        updateTrackingButtons()

    }
    
    func didDestinationAltitudeChange(altimiter : Altimiter){
        destinationLabel.text = altimiter.formatForDisplay(altimiter.destinationAltitude)
        hideStatusLabel()
    }
    
    
    
     /*** END Altimiter delegate protocol implementation ***/
    
    
    /** Private helper methods **/
    
    private func hideStatusLabel(){
        if !(statusHidden) {
            statusHidden = true
            UIView.animateWithDuration(1.0, delay: 5, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.statusLabel.alpha = 0
                }, completion: nil)
        }
        
        
    }
    
    
   private func updateProgress(myAltimiter: Altimiter){
        progress.hidden=false
        if myAltimiter.destinationAltitude > 0 && myAltimiter.calibratedAltitude > 0 {
            var percentComplete : NSNumber = 1 - (myAltimiter.destinationAltitude - myAltimiter.currentAltititude) / (myAltimiter.destinationAltitude - myAltimiter.startAltitude)
            if percentComplete.floatValue > 1  {
                percentComplete = 1
            }
            progress.progress = percentComplete.floatValue
            
        }
        
        
    }

   private func setFnishTime(altimiter: Altimiter){
        if altimiter.destinationAltitude > 0  && altimiter.getAssentRate().overall > 0 {
            finishTimeLabel.text = altimiter.getFinishTime()
        }else{
            finishTimeLabel.text = ""
        }
    }
    
    
}



