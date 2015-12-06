//
//  Step2InterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit

class Step2InterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print("awake with context: test VC")
        // Configure interface objects here.
        
        //connection & HealthKit setup
        self.setupWCConnection()
        self.setupHeartRateQuery()
        self.checkWCConnectReachable()
        
        
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        //reset hight
        if self.testIsStart {
            //test is already start
            self.group1.setRelativeHeight(0.0, withAdjustment: 0)
            //show message "keep finger on screen"
            self.animateFingerPrint()
            
        }else {
            //test is not start
            self.group1.setRelativeHeight(0.65, withAdjustment: 0)
            self.group2.setRelativeHeight(1.0, withAdjustment: 0)
            self.textLabel.sizeToFitHeight()
            self.textLabel.setAlpha(1.0)
            self.textLabel.setText("Keep your finger on screen")
            //hide for animation
            self.group2.setAlpha(0)
            self.stopButton.setAlpha(0)
            
        }
        
        print("will active: test VC")
    }

    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        
        
        print("did deactive: test VC")
        self.stopAnimateScan()
        super.didDeactivate()
    }
    
    override func didAppear() {
        print("did appear: test VC")
        //animation
        if testIsStart {
            
        }else {
            //start test
            self.stopAnimateScan()
            self.group2.setAlpha(0)
            self.firstAnimationTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("animatePress"), userInfo: nil, repeats: false)
            self.testIsStart = true
        }
        
        
    }
    
    
    
    @IBOutlet var pushButton: WKInterfaceButton!
    
    @IBOutlet var textLabel: WKInterfaceLabel!
    
    @IBOutlet var group1: WKInterfaceGroup!
    
    @IBOutlet var group2: WKInterfaceGroup!
    
    var firstAnimationTimer: NSTimer?
    
    @IBOutlet var stopButton: WKInterfaceButton!
    
    var dataValue = [Double]()

    
//WC connection
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    func setupWCConnection() {
        if let session = self.session {
            self.session?.delegate = self
            self.session?.activateSession()
            print("active session")
        }
    }
    
    func checkWCConnectReachable() -> Bool {
        
        if let session = session where session.reachable {
            self.setTitle("Cancel")
            
            return true
        }else {
            self.setTitle("Disconnected")
            return false
        }
    }
    
//Watch Connect function
    //receive
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print(message)
        if let cmd = message["cmd"] as? String {
            switch cmd {
            case "stop" :
                print("cmd from iphone: stop")
                replyHandler(["cmdResponse" : true])
                self.testIsStart = false
                
            case "start" :
                print("cmd from iphone: start")
                replyHandler(["cmdResponse" : true])
                self.testIsStart = true
                
                
            default :
                print("unknow cmd from iphone")
            }
        }
    }
    
    func sendCMDStopPhone() {
        if self.session!.reachable {
            print("send cmd to iphone: stop")
            self.session?.sendMessage(["cmd" : "stop"], replyHandler: nil, errorHandler: { (error) -> Void in
                print(error)
            })
        }
    }
    
    func sendCMDStartPhone() {
        if self.session!.reachable {
            print("send cmd to iphone: start")
            self.session?.sendMessage(["cmd" : "start"], replyHandler: nil, errorHandler: { (error) -> Void in
                print(error)
            })
        }
    }
    
    func sendDataFile(array : [NSDate : Double]) {
        print("send data to iOS device")
        let applicationData = ["heartRateData" : array]
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.session?.transferUserInfo(applicationData)
        }
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        if session.reachable {
            self.setTitle("Connected")
        }else {
            self.setTitle("Disconnected")
        }
    }
    
    
    
//health kit
    var healthStore = HKHealthStore()
    var anchorQuery: HKAnchoredObjectQuery?
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    let heartRateUnit = HKUnit(fromString: "count/min")
    var workOutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
    //status
    var testIsStart = false {
        didSet {
            if self.testIsStart {
                self.dataValue.removeAll()
                //test is running
                print("test is start")
                self.workOutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
                self.workOutSession.delegate = self
                self.healthStore.startWorkoutSession(self.workOutSession)
                self.sendCMDStartPhone()
            }else {
                //test is stop
                print("test is pause")
                self.healthStore.endWorkoutSession(self.workOutSession)
                
                
            }
        }
    }
    
    func sendHeartRateData(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        print("new heart rate data: ")
        
        for sample in heartRateSamples {
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            let time = sample.endDate
            var data = [NSDate : Double]()
            data[time] = value
            
            //save to local
            self.dataValue.append(value)
            print(data)
            
            //send to iphone
            self.sendDataFile(data)
        }
        
    }
    
    
    
    func setupHeartRateQuery() {
        let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        self.anchorQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: self.anchor, limit: Int(HKAnchoredObjectQueryNoAnchor), resultsHandler: { (query, sampleArray, deletArray, newAnchor, error) -> Void in
            if error != nil {
                print(error)
            }
            self.anchor = newAnchor!
            
            
        })
        self.anchorQuery!.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            print("anchor update query")
            self.anchor = newAnchor!
            self.sendHeartRateData(samples)
        }
        
    }
    
//health workout session
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            print("work out to state: Running")
            self.healthStore.executeQuery(self.anchorQuery!)
        case .Ended:
            print("work out to state: Ended")
            self.healthStore.stopQuery(self.anchorQuery!)
            
            
        case .NotStarted:
            print("work out to state: NotStarted")
            
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        print("fail for start work out")
        print(error)
    }
    

    
//initial animation
    func animatePress() {
        print("start first animation")
        
        
        //first press
        self.animatePressSize(0.8, time: 0.3)
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(300 * NSEC_PER_MSEC))
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            self.animatePressSize(0.65, time: 0.3)
        }
        
        let dispatchTime2 = dispatch_time(DISPATCH_TIME_NOW, Int64(600 * NSEC_PER_MSEC))
        dispatch_after(dispatchTime2, dispatch_get_main_queue()) { () -> Void in
            self.animatePressSize(0.9, time: 0.5)
            
        }
        let dispatchTime3 = dispatch_time(DISPATCH_TIME_NOW, Int64(1300 * NSEC_PER_MSEC)) //after 3 seconds
        dispatch_after(dispatchTime3, dispatch_get_main_queue()) { () -> Void in
            
            self.animateWithDuration(0.3, animations: { () -> Void in
                self.group1.setRelativeHeight(0.0, withAdjustment: 0)
                self.group2.setRelativeHeight(1.0, withAdjustment: 0)
                self.textLabel.setHeight(0)
                self.textLabel.setText("Keep your finger")
                self.group2.setAlpha(1.0)
            })
            
            self.startAnimateScan()
            
            
        }
    }
    
    func animatePressSize(ratio: CGFloat, time: NSTimeInterval) {
        self.animateWithDuration(time) { () -> Void in
            self.group1.setRelativeHeight(ratio, withAdjustment: 0)
        }
    }
    
//scan animation
    var animationTimer: NSTimer?
    func startAnimateScan() {
        self.animationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("animateScan"), userInfo: nil, repeats: true)
    }
    
    func stopAnimateScan() {
        print("stop animation")
        self.animationTimer?.invalidate()
        self.animationTimer = nil
        self.firstAnimationTimer?.invalidate()
        self.firstAnimationTimer = nil
        
    }
    
    
    func animateScan() {
        self.animateWithDuration(0.5) { () -> Void in
            self.group2.setAlpha(0.5)
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(500 * NSEC_PER_MSEC)) //after 1 seconds
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            
            self.animateWithDuration(0.5, animations: { () -> Void in
                self.group2.setAlpha(1.0)
            })
        }
        
    }

//finger print animation
    func animateFingerPrint() {
        self.stopAnimateScan()
        //animate button
        self.animateWithDuration(0.3) { () -> Void in
            self.textLabel.sizeToFitHeight()
            self.group2.setRelativeHeight(0.5, withAdjustment: 0.0)
            self.group2.setAlpha(1.0)
            self.stopButton.setAlpha(1.0)
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3000 * NSEC_PER_MSEC))
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            
            self.animateWithDuration(0.5, animations: { () -> Void in
                self.group2.setRelativeHeight(1.0, withAdjustment: 0)
                self.stopButton.setAlpha(0.0)
                self.textLabel.setHeight(0)
                
            })
            
        }
        
        let dispatchTime2 = dispatch_time(DISPATCH_TIME_NOW, Int64(4500 * NSEC_PER_MSEC))
        dispatch_after(dispatchTime2, dispatch_get_main_queue()) { () -> Void in
            self.startAnimateScan()
        }
    }
    
    
    
    
    
    
    
//button
    
    @IBAction func fingerPress() {
        print("finger press")
        self.animateFingerPrint()
    }
    
    
    @IBAction func stopButtonTouch() {
        print("stop Button touch")
        self.testIsStart = false
        //stop testing
        let file = session?.outstandingUserInfoTransfers.count
        print(file)
        if file > 0 {
            //wait transfer
            print("file is wait transfer: \(file)")
            
            return
            
        }else {
            self.sendCMDStopPhone()
            
            //segue with data
            self.presentControllerWithName("ResultVC", context: self.dataValue)
            
        }
    }
    
    
    
    

}
