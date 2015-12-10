//
//  AllowCameraViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/12/11.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class AllowCameraViewController: UIViewController {

    
    
    @IBOutlet weak var allowButton: UIButton!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func allowButtonTouche(sender: AnyObject) {
        print("allow camera button touch")
        
        self.alertAuthorizeCamera()
        
        
    }
    
    
    func setupView() {
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        
        //button
        self.allowButton.layer.cornerRadius = self.allowButton.frame.height / 2
        self.allowButton.clipsToBounds = true
    }
    
    
    
//camera func
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
    
    
    
    
    //alert
    func alertAuthorizeCamera() {
        let alert = UIAlertController(title: "Authorize", message: "We need to access camera", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (act) -> Void in
            switch act.style {
            case .Default:
                print("alert for access health data", terminator: "")
                self.authorizeCamera()
                self.authorizeAudio()
                self.authorizeCameraRoll()
                self.navigationController?.popViewControllerAnimated(true)
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertAuthorizeCameraFail() {
        let alert = UIAlertController(title: "Warning", message: "We need to access your camera and camera roll", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
