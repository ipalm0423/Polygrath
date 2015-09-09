//
//  TestInterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/8.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation
import UIKit
import WatchConnectivity
import HealthKit

class TestInterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {

    
    @IBOutlet var frontLabel: WKInterfaceLabel!

    @IBOutlet var startButton: WKInterfaceButton!
    
    
//WC
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
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
                //test is running
                print("test is start")
                self.healthStore.startWorkoutSession(self.workOutSession)
                self.frontLabel.setText("Running...")
                self.startButton.setTitle("Stop")
                self.startButton.setBackgroundColor(self.stopColor)
            }else {
                //test is stop
                print("test is pause")
                self.healthStore.endWorkoutSession(self.workOutSession)
                self.startButton.setTitle("Start")
                self.startButton.setBackgroundColor(self.startColor)
                self.frontLabel.setText("Pause")
            }
        }
    }
    
    let stopColor = UIColor(red: 0.909, green: 0.172, blue: 0047, alpha: 0.8)
    let startColor = UIColor(red: 0.082, green: 0.909, blue: 0.04, alpha: 0.8)
    
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        self.startButton.setBackgroundColor(self.startColor)
        self.checkWCConnection()
        self.setupHeartRateQuery()
        self.workOutSession.delegate = self
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    
    
    
    
//button
    
    @IBAction func startButtonTouch() {
        print("start button touch")
        if !self.checkWCConnection() {
            if self.testIsStart {
                self.testIsStart = false
            }
            return
        }
        self.testIsStart = self.testIsStart ? false : true
        
    }
    
    
//status func
    
    func checkWCConnection() -> Bool {
        if let session = session where session.reachable {
            self.setTitle("Connected")
            self.frontLabel.setText("Wearing the iWatch and press 'Start' button")
            
            self.session?.delegate = self
            self.session?.activateSession()
            self.startButton.setEnabled(true)
            return true
        }else {
            self.frontLabel.setText("Please check the connection between iWatch and iOS device")
            self.setTitle("Disconnected")
            self.startButton.setEnabled(false)
            return false
        }
    }
    
    
//health kit
    
    func sendHeartRateData(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        print("new heart rate data: ")
        var data = [NSDate : Double]()
        for sample in heartRateSamples {
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            let time = sample.endDate
            data[time] = value
            
        }
        print(data)
        self.sendArrayData(data)
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
            self.anchor = newAnchor!
            self.sendHeartRateData(samples)
        }
        
    }
    
    
//work out session
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
    
//Watch Connect function
    
    func sendArrayData(array : [NSDate : Double]) {
        let applicationData = ["heartRateData" : array]
        
        // The paired iPhone has to be connected via Bluetooth.
        if let session = session where session.reachable {
            print("send data to iOS device")
            session.sendMessage(applicationData,
                replyHandler: { replyData in
                    // handle reply from iPhone app here
                    print(replyData)
                }, errorHandler: { error in
                    // catch any errors here
                    print(error)
            })
        } else {
            print("device is not connected")
            self.checkWCConnection()
            // when the iPhone is not connected via Bluetooth
        }
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        if session.reachable {
            self.setTitle("Connected")
        }else {
            self.setTitle("Disconnected")
            
        }
    }
    
    
}
