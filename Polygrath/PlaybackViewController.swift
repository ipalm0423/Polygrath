//
//  PlaybackViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/12/18.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlaybackViewController: AVPlayerViewController {
    
    var url: NSURL!
    var questionIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        
        // Do any additional setup after loading the view.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        let player = AVPlayer(URL: self.url)
        self.player = player
        
        self.player!.play()
    }
    
    func setupView() {
        
        
        //button
        if let naviController = self.navigationController {
            print("setup forward button")
            navigationController?.navigationBarHidden = false

            let action = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("forwardButtonTouch:"))
            
            self.navigationItem.rightBarButtonItem = action
        }
    }
    
    func forwardButtonTouch(sender: UIBarButtonItem) {
        print("forward button touch")
        
        let alert = UIAlertController(title: "Share Video", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let row = self.questionIndex
        //camera roll
        let actionSaveToCamera = UIAlertAction(title: "Save to Camera Roll", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("save question.\(row) to camera roll")
            let url = Singleton.sharedInstance.questions[row].file.URL
            if let assetUrl = Singleton.sharedInstance.questions[row].file.assetURL {
                //already save to camera roll
                Singleton.sharedInstance.saveVideoToCameraRoll(assetUrl, completion: nil)
            }else {
                Singleton.sharedInstance.saveVideoToCameraRoll(url, completion: { (identifier, newUrl) -> Void in
                    Singleton.sharedInstance.questions[row].file.assetURL = newUrl
                })
            }
            
        })
        
        //facebook
        let actionShareFB = UIAlertAction(title: "Facebook", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("share question.\(row) to facebook")
            
            if let assetUrl = Singleton.sharedInstance.questions[row].file.assetURL {
                //already save to camera roll
                Singleton.sharedInstance.shareVideoToFacebook(assetUrl, targetVC: self)
            }else {
                //save to camera roll first
                let url = Singleton.sharedInstance.questions[row].file.URL
                Singleton.sharedInstance.shareVideoToFacebookAndCameraRoll(url, targetVC: self, completion: { (newURL) -> Void in
                    Singleton.sharedInstance.questions[row].file.assetURL = newURL
                })
            }
            
        })
        
        //messenger
        let actionShareMessenger = UIAlertAction(title: "Messenger", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("share question.\(row) to Messenger")
            let url = Singleton.sharedInstance.questions[row].file.URL
            if let assetUrl = Singleton.sharedInstance.questions[row].file.assetURL {
                //already save to camera roll
                Singleton.sharedInstance.shareVideoToMessenger(assetUrl)
            }else {
                //save to camera roll first
                Singleton.sharedInstance.shareVideoToMessengerAndCameraRoll(url, completion: { (assetUrl) -> Void in
                    Singleton.sharedInstance.questions[row].file.assetURL = assetUrl
                })
            }
        })
        
        //whatsapp
        let actionShareWhatsapp = UIAlertAction(title: "WhatsApp", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("share question.\(row) to WhatsApp")
            
        })
        
        
        
        //cancel
        let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            print("cancel to share video")
            
        })
        
        //add to alert
        alert.addAction(actionSaveToCamera)
        alert.addAction(actionShareFB)
        alert.addAction(actionShareMessenger)
        //alert.addAction(actionShareWhatsapp)
        alert.addAction(actionCancel)
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
