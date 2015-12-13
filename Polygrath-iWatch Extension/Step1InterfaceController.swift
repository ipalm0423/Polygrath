//
//  Step1InterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class Step1InterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.DoneButton.setHeight(0)
        self.DoneButton.setAlpha(0.0)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.animatePulse()
        self.startAnimate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.stopAnimate()
    }

    
    override func didAppear() {
        
        self.setupHealthStore()
        //done button
        let doneTimer = NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: Selector("doneButtonAnimate"), userInfo: nil, repeats: false)
        
    }
    
    @IBOutlet var image1: WKInterfaceImage!
    
    @IBOutlet var DoneButton: WKInterfaceButton!
    
    
    
    
    var animationTimer: NSTimer?
    
    func doneButtonAnimate() {
        self.animateWithDuration(0.5) { () -> Void in
            self.DoneButton.setHeight(30)
            self.DoneButton.setAlpha(1.0)
        }
        
    }
    
    func startAnimate() {
        
        self.animationTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("animatePulse"), userInfo: nil, repeats: true)
    }
    
    func stopAnimate() {
        self.animationTimer?.invalidate()
        self.animationTimer = nil
    }
    
    func animatePulse() {
        self.image1.setRelativeWidth(1.0, withAdjustment: 0.0)
        self.animateWithDuration(2) { () -> Void in
            self.image1.setRelativeWidth(0.0, withAdjustment: 0)
        }
        
        
    }
    
    
    var healthStore = HKHealthStore()
    
    func setupHealthStore() -> Bool {
        if HKHealthStore.isHealthDataAvailable() {
            let heartRateType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            let typetoShare = Set(arrayLiteral: heartRateType)
            let typetoRead = Set(arrayLiteral: heartRateType)
            let status = healthStore.authorizationStatusForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!)
            
            if status == HKAuthorizationStatus.NotDetermined || status == HKAuthorizationStatus.SharingDenied {
                print("HK not authorize")
                self.healthStore.requestAuthorizationToShareTypes(typetoShare, readTypes: typetoRead, completion: { (bool, error) -> Void in
                    if let ER = error {
                        print(ER)
                    }
                    if bool {
                        print("agree HK")
                        
                    }else {
                        print("didn't agree HK")
                        
                    }
                })
                self.showAlert("Can't Access Health Data", message: "Adjust setting in 'Health' app on your iPhone", completion: { () -> Void in
                    print("seage to checkVC")
                    self.presentControllerWithName("checkVC", context: nil)
                })
                return false
                
            }else {
                return true
            }
            
        }else {
            self.showAlert("Please Upgrage", message: "Your device is not support", completion: nil)
            return false
        }
    }
    
    
    
    
    
    //alert
    func showAlert(title: String, message: String, completion: (() -> Void)?) {
        
        let action = WKAlertAction(title: "Ok", style: WKAlertActionStyle.Default) { () -> Void in
            print("Warning: \(message)")
            completion?()
        }
        
        presentAlertControllerWithTitle(title, message: message, preferredStyle: .ActionSheet, actions: [action])
        
    }
    
    
}
