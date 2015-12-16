//
//  RecordViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/22.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
//import Charts


class RecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    //constant
    let pageControl = 1
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var emptyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Singleton.sharedInstance.questions.count == 0 {
            self.emptyLabel.alpha = 1
        }
        
        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 250
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(animated: Bool) {
        print("record VC did appear")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tableReload:"), name: "questionReload", object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "questionReload", object: nil)
    }
    
    func tableReload(notify: NSNotification) {
        print("question reload, table reloaded")
        self.tableView.reloadData()
    }
    
    
//table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Singleton.sharedInstance.questions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("recordCell") as! RecordTableViewCell
        let question = Singleton.sharedInstance.questions[indexPath.row]
        print("build cell row: \(indexPath.row), question data: \(question.dataValues), question date: \(question.dataDates)")
        
        cell.playButton.tag = indexPath.row
        
        //cell.forwardButton.tag = indexPath.row
        
        //label setting
        //cell.timeLabel.text = Singleton.sharedInstance.getTimeString(question.startTime, stopTime: question.endTime)
        cell.questionNoLabel.text = "Question." + (indexPath.row + 1).description
        cell.processView.alpha = 0.0 //wait for process
        
        if question.dataValues.count > 0 {
            //have data
            cell.truthLabel.text = Int(question.score * 100).description + "%"
            cell.maxLabel.text = String(format: "%.0f", question.max)
            cell.avgLabel.text = String(format: "%.0f", question.average)
            
            //setup graph
            cell.quest = question
            cell.setupPlotGraph(CGSize(width: self.view.bounds.width - 60, height: cell.chartView.frame.height))
            
        }else {
            //no data
            cell.truthLabel.text = "0"
            cell.maxLabel.text = "0"
            cell.avgLabel.text = "0"
            
        }
        
        
        
        
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 230
    }

    
    
    
    
    
//video
    func playBackVideo(url: NSURL) {
        
        let player = AVPlayer(URL: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        /*
        self.presentViewController(playerViewController, animated: true) {
        playerViewController.player!.play()
        }*/
        if let navi = self.navigationController {
            navi.pushViewController(playerViewController, animated: true)
        }
    }
    
    
//button
    
    @IBAction func playButtonTouchDown(sender: AnyObject) {
        print("play button touch \(sender.tag)")
        
        
        
    }
    
    
    
    @IBAction func playButtonTouch(sender: AnyObject) {
        if let tag = sender.tag {
           self.playBackVideo(Singleton.sharedInstance.questions[tag].file.URL)
        }
    }
    
    
    @IBAction func forwardButtonTouch(sender: AnyObject) {
        if let row = sender.tag {
            print("press forward button on row: \(row)")
            let alert = UIAlertController(title: "Share Video", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            //camera roll
            let actionSaveToCamera = UIAlertAction(title: "Save to Camera Roll", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                print("save question.\(row) to camera roll")
                let url = Singleton.sharedInstance.questions[row].file.URL
                Singleton.sharedInstance.saveVideoToCameraRoll(url, completion: { (identifier, newUrl) -> Void in
                    Singleton.sharedInstance.questions[row].file.assetURL = newUrl
                })
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
            
            //test
            let actionTest = UIAlertAction(title: "test", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                //check if video progress before
                
                
                Singleton.sharedInstance.videoComposeWithQuestion(row)
                
                
                
            })
            
            //cancel
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                print("cancel to share video")
                
            })
            
            //add to alert
            alert.addAction(actionSaveToCamera)
            alert.addAction(actionShareFB)
            alert.addAction(actionShareMessenger)
            alert.addAction(actionTest)
            //alert.addAction(actionShareWhatsapp)
            alert.addAction(actionCancel)
            self.presentViewController(alert, animated: true, completion: nil)
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
