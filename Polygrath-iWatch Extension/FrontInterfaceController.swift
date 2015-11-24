//
//  FrontInterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class FrontInterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        self.setupHealthStoreWithoutAlert()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.stopAnimate()
    }
    
    var animationTimer: NSTimer?
    
    override func didAppear() {
        self.startAnimate()
        print("did appear")
        
    }
    
    @IBOutlet var image1: WKInterfaceImage!
    
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
    
    
//health kit
    var healthStore = HKHealthStore()
    
    func setupHealthStoreWithoutAlert() -> Bool {
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
                
                return false
                
            }else {
                return true
            }
            
        }else {
            
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
