//
//  ResultPageViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/16.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class ResultPageViewController: UIViewController {
    
    //controll button action
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(animated: Bool) {
        self.setupNotify()
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.removeNotify()
    }
    
    
    

    
    
//button
    @IBOutlet weak var reportButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    
    
    @IBAction func reportButtonTouch(sender: AnyObject) {
        print("report button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveBackward", object: nil)
        //animate
        self.reportButtonAnimate()
        
    }
    
    @IBAction func recordButtonTouch(sender: AnyObject) {
        print("record button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveForward", object: nil)
        //animate
        self.recordButtonAnimation()
        
    }

    
    
    
//notifycation
    func setupNotify() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reportButtonNotify:"), name: "reportButtonTouch", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("recordButtonNotify:"), name: "recordButtonTouch", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("restartButtonNotify:"), name: "restartButtonTouch", object: nil)
    }
    
    func removeNotify() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "reportButtonTouch", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "recordButtonTouch", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "restartButtonTouch", object: nil)
    }
    func reportButtonNotify(notify: NSNotification) {
        self.reportButtonAnimate()
    }
    
    func recordButtonNotify(notify: NSNotification) {
        self.recordButtonAnimation()
    }
    
    func restartButtonNotify(notify: NSNotification) {
        print("restart test")
        //back to restart, don't save anything
        let count = self.navigationController!.viewControllers.count
        if let switchViewController = self.navigationController?.viewControllers[count - 3] as? IntroViewController {
            print("restart test: sucess")
            self.navigationController?.popToViewController(switchViewController, animated: true)
        }
    }
    
    
    
    
    
//animation
    
    func reportButtonAnimate() {
        self.reportButton.setImage(UIImage(named: "report-press"), forState: UIControlState.Normal)
        self.reportButton.setTitleColor(UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0), forState: UIControlState.Normal)
        self.reportButton.backgroundColor = UIColor.clearColor()
        self.recordButton.setImage(UIImage(named: "record-unpress"), forState: UIControlState.Normal)
        self.recordButton.setTitleColor(UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1.0), forState: UIControlState.Normal)
        self.recordButton.backgroundColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 0.2)
    }
    
    func recordButtonAnimation() {
        self.reportButton.setImage(UIImage(named: "report-unpress"), forState: UIControlState.Normal)
        self.reportButton.setTitleColor(UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1.0), forState: UIControlState.Normal)
        self.reportButton.backgroundColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 0.2)
        self.recordButton.setImage(UIImage(named: "record-press"), forState: UIControlState.Normal)
        self.recordButton.setTitleColor(UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0), forState: UIControlState.Normal)
        self.recordButton.backgroundColor = UIColor.clearColor()
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
