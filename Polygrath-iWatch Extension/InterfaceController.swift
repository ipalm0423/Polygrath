//
//  InterfaceController.swift
//  Polygrath-iWatch Extension
//
//  Created by 陳冠宇 on 2015/9/8.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    
    @IBOutlet var frontLabel: WKInterfaceLabel!
    
    
    
    let session : WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    var healthStore = HKHealthStore()
    
    override init() {
        super.init()
        
        session?.delegate = self
        session?.activateSession()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    @IBAction func comfirmButtonTouch() {
        print("comfirm button touch")
        if let session = session where session.reachable {
            if !self.setupHealthStore() {
                self.frontLabel.setText("Authorize Polygrath to access Health data")
                return
            }
            print("iOS app is reachable")
            self.pushControllerWithName("testController", context: nil)
        }else {
            self.frontLabel.setText("Doesn't found any paired device")
            self.checkWCConnection()
        }
    }
    
    override func updateUserActivity(type: String, userInfo: [NSObject : AnyObject]?, webpageURL: NSURL?) {
        print("hand off")
    }
    
    
//wc session
    
    func checkWCConnection() -> Bool {
        if let session = session {
            self.frontLabel.setText("Wearing the iWatch and press 'Start' button")
            
            self.session?.delegate = self
            self.session?.activateSession()
            
            return true
        }else {
            self.frontLabel.setText("Please check the connection between iWatch and iOS device")
            
            return false
        }
    }
    
//navi
    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
        if segueIdentifier == "" {
            
        }
        
        return nil
    }
    
    
//health store
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
                return false
                
            }else {
                return true
            }
            
        }else {
            self.frontLabel.setText("Your device is not support.")
            return false
        }
    }
    
    

}
