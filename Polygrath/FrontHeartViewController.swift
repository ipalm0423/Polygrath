//
//  FrontHeartViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/15.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import Foundation
import WatchConnectivity
import AVFoundation

class FrontHeartViewController: UIViewController,WCSessionDelegate {

    @IBOutlet weak var heartImage: UIImageView!
    var snapHeart = UIView()
    
    //WCSession
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        self.animateHeart()
    }
    
    
//animate
    func animateHeart() {
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        self.snapHeart = self.heartImage.snapshotViewAfterScreenUpdates(true)
        self.snapHeart.frame = self.heartImage.frame
        self.view.addSubview(self.snapHeart)
        
        UIView.animateWithDuration(0.375, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.Repeat], animations: { () -> Void in
            
            self.snapHeart.transform = CGAffineTransformMakeScale(1.2, 1.2)
            }) { (Bool) -> Void in
                
        }
    }
    
//alert
    func alertAuthorizeCamera() {
        let alert = UIAlertController(title: "Authorize", message: "We need to access camera", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (act) -> Void in
            switch act.style {
            case .Default:
                print("alert for access health data", terminator: "")
                self.authorizeCamera()
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertAuthorizeCameraFail() {
        let alert = UIAlertController(title: "Fail", message: "We can't access camera", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
//camera
    func checkCameraAuthorize() -> Bool {
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized {
            return true
        }else {
            return false
        }
    }
    
    func authorizeCamera() {
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized {
            // Already Authorized
            print("user already authorize camera access")
            //setup
            /*
            let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            for device in availableCameraDevices as! [AVCaptureDevice] {
                if device.position == .Back {
                    backCameraDevice = device
                }
                else if device.position == .Front {
                    frontCameraDevice = device
                }
            }*/
            //perform segue
            self.performSegueWithIdentifier("VideoSegue", sender: self)
        }
        else {
            print("user haven't authorize camera access")
            //request
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in if granted == true {
                    // User granted
                print("user authorize camera access")
                self.performSegueWithIdentifier("VideoSegue", sender: self)
                
                }
                else {
                    // User Rejected
                print("user not allow camera authorize")
                self.alertAuthorizeCameraFail()
                return
                }
            });
        }
        
    }

    
    
    @IBAction func startButtonTouch(sender: AnyObject) {
        /*
        print("press start button", terminator: "")
        if WCSession.isSupported() {
            if let session = session where session.reachable {
                
                print("iWatch is reachable")
                self.performSegueWithIdentifier("TestSegue", sender: self)
            }else {
                print("iWatch is not reachable")
                let alert = UIAlertController(title: "Connected Fail", message: "Please check your connection with iWatch", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }else {
            print("not support WCSession")
            let alert = UIAlertController(title: "Not Support", message: "Your iOS device is not support, please upgrade", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }*/
        
        self.performSegueWithIdentifier("TestSegue", sender: self)
    }
    
    
    @IBAction func StartVideoTestButton(sender: AnyObject) {
        print("startVideoButton touch")
        if self.checkCameraAuthorize() {
            self.performSegueWithIdentifier("VideoSegue", sender: self)
        }else {
            self.alertAuthorizeCamera()
        }
        
    }
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



