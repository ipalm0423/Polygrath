//
//  IntroPageViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/12/10.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class IntroPageViewController: UIViewController {
    
    var pageIndex: Int? 
    var titleText : String!
    var subTitleText: String!
    var imageName : String!

    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    
    @IBOutlet weak var startButton: UIButton!
    
    
    @IBOutlet weak var startButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var heartImage: UIImageView!

    
    @IBOutlet var fingerPrintImageView: UIImageView!
    
    @IBOutlet var fingerPrintBTMConst: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        
        
        
        
        
    }

    
    func setupView() {
        //image, title
        self.titleLabel.text = self.titleText
        self.subTitleLabel.text = self.subTitleText
        self.imageView.image = UIImage(named: self.imageName)
        self.pageControl.currentPage = self.pageIndex!
        
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        
        //self.startButton.layer.cornerRadius = self.startButton.frame.height / 2
        //self.startButton.clipsToBounds = true
        //button
        if self.pageIndex != 2 {
            //heart image
            self.heartImage.alpha = 0
            self.startButton.alpha = 0
        }else {
            //ready View setup
            self.titleLabel.font = UIFont(name: "HelveticaNeue", size: 60)
            
        }
        
        //finger print
        if self.pageIndex == 1 {
            self.fingerPrintImageView.alpha = 1
            self.fingerPrintImageView.updateConstraintsIfNeeded()
            self.fingerPrintBTMConst.constant = self.fingerPrintImageView.frame.height / 2
        }
        
        
        //self.startButton.setNeedsUpdateConstraints()
        //self.startButtonBottomConstraint.constant = -60 //hide
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if let index = self.pageIndex {
            switch index {
            case 0:
                print("page. 0: open watch app")
                //animate iWatch
                self.iWatchTimer = NSTimer.scheduledTimerWithTimeInterval(0.6, target: self, selector: Selector("animateiWatch"), userInfo: nil, repeats: true)
                
            case 1:
                print("page. 1: keep finger touch")
                self.animateFinger()
                
            case 2:
                print("page. 2: Ready page, camera authorize")
                //animation heart
                self.animateHeart()
                
                /*
                UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.CurveEaseIn], animations: { () -> Void in
                    
                    //self.startButtonBottomConstraint.constant = 20
                    self.startButton.layoutIfNeeded()
                    }, completion: { (finished) -> Void in
                        print("")
                })
                */
            default:
                print("error page")
            }
        }
        
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    
    
//animation
    var snapHeart = UIView()
    func animateHeart() {
        //remove previous one
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        //add new one
        self.snapHeart = self.heartImage.snapshotViewAfterScreenUpdates(true)
        self.snapHeart.frame = self.heartImage.frame
        self.view.addSubview(self.snapHeart)
        
        UIView.animateWithDuration(0.375, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.Repeat], animations: { () -> Void in
            
            self.snapHeart.transform = CGAffineTransformMakeScale(1.2, 1.2)
            }) { (Bool) -> Void in
                
        }
    }
    
    var iWatchTimer = NSTimer()
    var i = 0
    func animateiWatch() {
        
        self.i++
        if i % 3 == 1 {
            self.imageView.image = UIImage(named: "iwatchIntro3")
        }else if i % 3 == 2 {
            self.imageView.image = UIImage(named: "iwatchIntro2")
        }else {
            self.imageView.image = UIImage(named: "iwatchIntro1")
        }
    }
    
    
    var snapFinger = UIView()
    func animateFinger() {
        
        self.imageView.alpha = 1
        self.snapFinger = self.imageView.snapshotViewAfterScreenUpdates(false)
        let oldFrame = self.imageView.frame
        self.snapFinger.frame = oldFrame
        self.view.addSubview(self.snapFinger)
        self.view.bringSubviewToFront(self.snapFinger)
        self.imageView.alpha = 0 //hide original
        self.snapFinger.alpha = 1
        
        UIView.animateWithDuration(0.7, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.Repeat], animations: { () -> Void in
            
            self.snapFinger.frame = CGRect(x: oldFrame.origin.x, y: oldFrame.origin.y - 50, width: oldFrame.width, height: oldFrame.height)
            }) { (Bool) -> Void in
                print("remove snap finger from view")
                self.snapFinger.removeFromSuperview()
        }
        
    }
    
    
    
    
    
    
//button
    
    @IBAction func startButtonTouch(sender: AnyObject) {
        print("segue to video test")
        
        //authorize camera
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) !=  AVAuthorizationStatus.Authorized || AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) != AVAuthorizationStatus.Authorized {
            self.alertCameraWarning()
        }else {
            //to zero
            Singleton.sharedInstance.BPMAverage = 0
            Singleton.sharedInstance.BPMDeviation = 0
            Singleton.sharedInstance.BPMmax = 0
            Singleton.sharedInstance.BPMmin = 0
            Singleton.sharedInstance.questions = [question]()
            Singleton.sharedInstance.totalTruthRate = nil
            //authorize success
            self.performSegueWithIdentifier("StartTestSegue", sender: self)
        }
        
    }
    
    
    
    
    
//alert
    func alertCameraWarning() {
        let alert = UIAlertController(title: "Authorize", message: "Need to Access Camera for Polygraph Purpose", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("alert for access camera", terminator: "")
                //not allow health store
                if let allowView = self.storyboard?.instantiateViewControllerWithIdentifier("AllowCamera") as? AllowCameraViewController {
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
