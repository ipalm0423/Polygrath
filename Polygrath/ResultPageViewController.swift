//
//  ResultPageViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/16.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class ResultPageViewController: UIViewController {
    
    
    //constant
    var BPMAverage: Double = 0
    var BPMDeviation: Double = 0
    var BPMmax: Double = 0
    var BPMmin: Double = 0
    var questions = [question]()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        let gradientLayer = Singleton.sharedInstance.getBackgroundGradientLayer(self.view.bounds)
        self.view.layer.insertSublayer(gradientLayer, atIndex: 0)
        if let bar = self.navigationController?.navigationBar {
            print("navi color setup")
            self.navigationController?.navigationBarHidden = false
            let naviImage = Singleton.sharedInstance.getNaviBarGradientLayer(bar.bounds)
            bar.translucent = false
            let fontDictionary: [String: AnyObject] = [ NSForegroundColorAttributeName:UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0), NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 24)! ]
            bar.titleTextAttributes = fontDictionary
            bar.tintColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0)
            bar.setBackgroundImage(naviImage, forBarMetrics: UIBarMetrics.Default)
            
            
        }
        
        
    }

    
    
//button
    @IBOutlet weak var reportButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    
    
    @IBAction func reportButtonTouch(sender: AnyObject) {
        print("report button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveBackward", object: nil)
    }
    
    @IBAction func recordButtonTouch(sender: AnyObject) {
        print("record button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("pageMoveForward", object: nil)
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
