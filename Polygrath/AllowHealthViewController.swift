//
//  AllowHealthViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/12/10.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import HealthKit

class AllowHealthViewController: UIViewController {

    var healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func setupView() {
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        
        //button
        //self.allowButton.layer.cornerRadius = self.allowButton.frame.height / 2
        //self.allowButton.clipsToBounds = true
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
                        print("did feedback HK permission.", terminator: "")
                        if self.healthStore.authorizationStatusForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!) == HKAuthorizationStatus.SharingAuthorized {
                            print("allow check ok")
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.navigationController?.popViewControllerAnimated(true)
                            })
                            
                            
                        }else {
                            //authorize denny
                            self.alertHealthWarning("We need to access your health data for polygraph purpose")
                        }
                    }else {
                        print("didn't reply HK authorization", terminator: "")
                        self.alertHealthWarning("We need to access your health data for polygraph purpose")
                    }
                })
                print("health store is not authorize", terminator: "")
                return false
                
            }else {
                print("Authorize success", terminator: "")
                self.navigationController?.popViewControllerAnimated(true)
                
                return true
            }
            
        }else {
            print("health store is not available", terminator: "")
            self.alertHealthWarning("Your device is not support, Please upgrade!")
            
            return false
        }
    }
    
    func alertHealthWarning(text: String) {
        let alert = UIAlertController(title: "Unauthorized", message: text, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("alert for access health data", terminator: "")
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBOutlet weak var allowButton: UIButton!
    
    @IBAction func allowButtonTouch(sender: AnyObject) {
        print("allow health button touch")
        
        self.setupHealthStore()
        
    }
    
    

}
