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
    
    
    @IBOutlet var statementButton: UIButton!
    
    
    @IBOutlet var welcomeImageLeadConst: NSLayoutConstraint!
    
    
    
    @IBOutlet var welcomeLineImage: UIImageView!
    
    //@IBOutlet var reflectionImageView: UIImageView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupView()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var isAnimate = false
    
    override func viewDidAppear(animated: Bool) {
        self.animateLine()
        print("view did appear")
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        print("view did disappear")
    }
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    var firstImageView = UIImageView()
    var reflectView = UIImageView()
    var secondImageView = UIImageView()
    
    func setupView() {
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        Singleton.sharedInstance.setupNaviBarColor(self)
        self.statementButton.layer.cornerRadius = self.statementButton.frame.height / 2
        self.statementButton.clipsToBounds = true
        
        
        
        
    }
    
    


    
//alert func
    
    func alertNotSupportDevice() {
        let alert = UIAlertController(title: "Not Support", message: "Your iOS device is not support in HealthKit, please upgrade", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertHealthWarning() {
        let alert = UIAlertController(title: "Authorize", message: "Need to Access Health Data Before Start", preferredStyle: UIAlertControllerStyle.Alert)
        
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
    
    
//animation
    func animateLine() {
        self.firstImageView.removeFromSuperview()
        self.reflectView.removeFromSuperview()
        self.secondImageView.removeFromSuperview()
        
        //setup image
        if let image = welcomeLineImage.image {
            //setup image 2nd
            self.firstImageView.image = image
            self.secondImageView.image = image
            //setup reflect image
            let reflect = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: UIImageOrientation.UpMirrored)
            self.reflectView.image = reflect
        }
        
        let original = self.welcomeLineImage.frame
        self.firstImageView.frame = CGRect(x: 0 , y: original.origin.y, width: original.width, height: original.height)
        self.reflectView.frame = CGRect(x: original.width - 2 , y: original.origin.y, width: original.width, height: original.height)
        self.secondImageView.frame = CGRect(x: original.width * 2 - 4, y: original.origin.y, width: original.width, height: original.height)
        self.view.addSubview(self.firstImageView)
        self.view.addSubview(self.reflectView)
        self.view.addSubview(self.secondImageView)
        self.welcomeLineImage.hidden = true
        print("welcome frame: \(self.welcomeLineImage.frame)")
        
        
        UIView.animateWithDuration(10, delay: 0, options: [UIViewAnimationOptions.Repeat, UIViewAnimationOptions.CurveLinear], animations: { () -> Void in
            
            self.firstImageView.frame = CGRect(x: -self.welcomeLineImage.frame.width * 2 + 4, y: original.origin.y, width: original.width, height: original.height)
            self.reflectView.frame = CGRect(x: -self.welcomeLineImage.frame.width + 2, y: original.origin.y, width: original.width, height: original.height)
            self.secondImageView.frame = original
            self.view.layoutIfNeeded()
            }) { (bool) -> Void in
                //self.lineStackView.frame = CGRect(x: 0, y: original.origin.y, width: self.view.frame.width * 3, height: original.height)
        }
        
        
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

