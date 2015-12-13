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
    
    @IBOutlet weak var startButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupView()
        
        
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

    func setupView() {
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        Singleton.sharedInstance.setupNaviBarColor(self)
        //self.startButton.layer.cornerRadius = self.startButton.frame.height / 2
        //self.startButton.clipsToBounds = true
    }
    
    


    
//alert func
    
    func alertNotSupportDevice() {
        let alert = UIAlertController(title: "Not Support", message: "Your iOS device is not support in HealthKit, please upgrade", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertHealthWarning() {
        let alert = UIAlertController(title: "Authorize", message: "Need to Access Health Data for Polygraph Purpose", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("alert for access health data", terminator: "")
                //not allow health store
                if let allowView = self.storyboard?.instantiateViewControllerWithIdentifier("AllowHealth") as? AllowHealthViewController {
                    self.navigationController?.pushViewController(allowView, animated: true)
                }
                
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

