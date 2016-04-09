//
//  StatementViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/28.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class StatementViewController: UIViewController {

    
    @IBOutlet var privacyButton: UIButton!
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
        self.navigationController?.navigationBarHidden = false
        self.privacyButton.layer.cornerRadius = self.privacyButton.frame.height / 2
        self.privacyButton.clipsToBounds = true
        self.textView.scrollsToTop = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
