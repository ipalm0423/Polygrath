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
        Singleton.sharedInstance.setupGradientColorView(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
        
        
    

    
    
//button
    @IBOutlet weak var reportButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    
    
    @IBAction func reportButtonTouch(sender: AnyObject) {
        print("report button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveBackward", object: nil)
        //animate
        
        
        
        
    }
    
    @IBAction func recordButtonTouch(sender: AnyObject) {
        print("record button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveForward", object: nil)
        //animate
        
        
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
