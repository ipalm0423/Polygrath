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
import Photos

class FrontHeartViewController: UIViewController,WCSessionDelegate {

    @IBOutlet weak var heartImage: UIImageView!
    var snapHeart = UIView()
    
    @IBOutlet weak var checkButton: UIButton!
    
    @IBOutlet weak var tempStartButton: UIButton!
    
    
    
    //WCSession
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        self.animateHeart()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    
//view
    func setupView() {
        self.navigationController?.navigationBarHidden = false
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        //self.checkButton.layer.cornerRadius = self.checkButton.frame.height / 2
        //self.checkButton.clipsToBounds = true
        self.tempStartButton.hidden = true
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
        let alert = UIAlertController(title: "Authorize", message: "Need to Access Camera", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (act) -> Void in
            switch act.style {
            case .Default:
                print("alert for access health data", terminator: "")
                self.authorizeCamera()
                self.authorizeAudio()
                self.authorizeCameraRoll()
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertAuthorizeCameraFail() {
        let alert = UIAlertController(title: "Warning", message: "Need to Access Camera and Camera Roll", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
//camera
    
    func authorizeCamera() -> Bool {
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
            
            return true
        }else {
            print("user haven't authorize camera access")
            //request
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (bool) -> Void in
                if bool {
                    print("user authorize camera access")
                    return
                    
                }else {
                    print("user not allow camera authorize")
                    self.alertAuthorizeCameraFail()
                    return
                    
                }
            })
            return false
        }
    }
    
    func authorizeAudio() -> Bool {
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) == AVAuthorizationStatus.Authorized {
            print("user already authorize audio access")
            
            return true
        }else {
            print("user haven't authorize audio access")
            //request
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler: { (bool) -> Void in
                if bool {
                    //authorized
                    return
                    
                }else {
                    //user rejected
                    print("user not allow audio authorize")
                    self.alertAuthorizeCameraFail()
                    return
                    
                }
            })
            return false
        }
    }

    func authorizeCameraRoll() -> Bool {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            print("user already authorize camera roll access")
            return true
        }else {
            print("user haven't authorize camera roll access")
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                
                if status == PHAuthorizationStatus.Authorized {
                    print("user allow camera roll access")
                    return
                }else {
                    print("user didn't allow camera roll access")
                    self.alertAuthorizeCameraFail()
                    return
                }
            })
        }
        return false
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
        if self.authorizeCamera() && self.authorizeAudio() && self.authorizeCameraRoll() {
            self.performSegueWithIdentifier("VideoSegue", sender: self)
        }else {
            self.alertAuthorizeCamera()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "VideoSegue" {
            Singleton.sharedInstance.createAlbum()
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



