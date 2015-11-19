//
//  ViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/8.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import HealthKit


class ViewController: UIViewController {

    
    var healthStore = HKHealthStore()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupNaviBarColor(self)
        self.alertHealthWarning()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }

    
    
//health store
    func setupHealthStore() -> Bool {
        if HKHealthStore.isHealthDataAvailable() {
            let heartRateType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            let typetoShare = Set(arrayLiteral: heartRateType)
            let typetoRead = Set(arrayLiteral: heartRateType)
            let status = healthStore.authorizationStatusForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!)
            
            if status == HKAuthorizationStatus.NotDetermined || status == HKAuthorizationStatus.SharingDenied {
                print("HK not authorize", terminator: "")
                self.healthStore.requestAuthorizationToShareTypes(typetoShare, readTypes: typetoRead, completion: { (bool, error) -> Void in
                    if let ER = error {
                        print(ER, terminator: "")
                    }
                    if bool {
                        print("did feedback HK permission. but denied", terminator: "")
                    }else {
                        print("didn't reply HK authorization", terminator: "")
                    }
                })
                print("health store is not authorize", terminator: "")
                return false
                
            }else {
                print("Authorize success", terminator: "")
                return true
            }
            
        }else {
            print("health store is not available", terminator: "")
            //self.frontLabel.setText("Your device is not support.")
            return false
        }
    }

    
//alert func
    
    func alertNotSupportDevice() {
        let alert = UIAlertController(title: "Not Support", message: "Your iOS device is not support in HealthKit, please upgrade", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertHealthWarning() {
        let alert = UIAlertController(title: "Notice", message: "We need to access your health data for polygrath purpose", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("alert for access health data", terminator: "")
                self.setupHealthStore()
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    

//button 
    @IBAction func startButtonTouch(sender: AnyObject) {
        print("press start button", terminator: "")
        
        if (HKHealthStore.isHealthDataAvailable()) {
            let status = healthStore.authorizationStatusForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!)
            if status == HKAuthorizationStatus.NotDetermined || status == HKAuthorizationStatus.SharingDenied {
                self.alertHealthWarning()
            }else {
                self.performSegueWithIdentifier("StartSegue", sender: self)
            }
        }else {
            print("device is not support in health kit", terminator: "")
            self.alertNotSupportDevice()
        }
    }
    
   
    
}

