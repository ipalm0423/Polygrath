//
//  ViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/8.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {

    var healthStore = HKHealthStore()
    
    @IBOutlet weak var textView: UITextView!
    
    var data = [NSDate : Double]()
    
//WCSession
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setupHealthStore()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        self.checkWCConnection()
    }
    
    
    
//WCSession
    func checkWCConnection() {
        if WCSession.isSupported() {
            session?.delegate = self
            session?.activateSession()
            if let isConnect = session?.reachable {
                print("session reachable: \(isConnect)")
            }
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        
        if let dics = message["heartRateData"] as? [NSDate : Double] {
            dispatch_async(dispatch_get_main_queue()) {
                for dic in dics {
                    self.data[dic.0] = dic.1
                }
                self.textView.text = self.data.description
            }
        }
        
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
                        print("did feedback HK permission. but denied")
                    }else {
                        print("didn't reply HK authorization")
                    }
                })
                print("health store is not authorize")
                return false
                
            }else {
                print("Authorize success")
                return true
            }
            
        }else {
            print("health store is not available")
            //self.frontLabel.setText("Your device is not support.")
            return false
        }
    }

    
    
    
    

    
   
    
}

