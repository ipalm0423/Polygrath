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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIView {
    /**
    Set x Position
    
    - parameter x: CGFloat
    by DaRk-_-D0G
    */
    func setX(x:CGFloat) {
        var frame:CGRect = self.frame
        frame.origin.x = x
        self.frame = frame
    }
    /**
    Set y Position
    
    - parameter y: CGFloat
    by DaRk-_-D0G
    */
    func setY(y:CGFloat) {
        var frame:CGRect = self.frame
        frame.origin.y = y
        self.frame = frame
    }
    /**
    Set Width
    
    - parameter width: CGFloat
    by DaRk-_-D0G
    */
    func setWidth(width:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.width = width
        self.frame = frame
    }
    /**
    Set Height
    
    - parameter height: CGFloat
    by DaRk-_-D0G
    */
    func setHeight(height:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.height = height
        self.frame = frame
    }
}
