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
import CorePlot

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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("videoComposeFinished:"), name: "videoCompose", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(animated: Bool) {
        print("record VC did appear")
        self.tableView.reloadData()
    }
    
    
    
    override func viewDidDisappear(animated: Bool) {
        
    }
    
    
//notifycation
    func videoComposeFinished(notify: NSNotification) {
        if let userinfo = notify.userInfo as? Dictionary<String,AnyObject> {
            //check roomid
            if let row = userinfo["index"] as? Int {
                self.stopAnimateBarPlot(NSIndexPath(forRow: row, inSection: 0))
                
            }
        }
    }
    
//table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Singleton.sharedInstance.questions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("recordCell") as! RecordTableViewCell
        let question = Singleton.sharedInstance.questions[indexPath.row]
        print("build cell row: \(indexPath.row), question data: \(question.dataValues), question date: \(question.dataDates)")
        
        cell.playButton.tag = indexPath.row
        
        //cell.forwardButton.tag = indexPath.row
        
        //label setting
        //cell.timeLabel.text = Singleton.sharedInstance.getTimeString(question.startTime, stopTime: question.endTime)
        cell.questionNoLabel.text = "Record " + (indexPath.row + 1).description
        cell.questionNoLabel.layer.cornerRadius = cell.questionNoLabel.frame.height / 2
        cell.questionNoLabel.clipsToBounds = true
        cell.processIndicator.alpha = 0.0 //wait for process
        cell.processLabel.alpha = 0 //wait for process
        cell.chartView.backgroundColor = UIColor(red: 16 / 255, green: 16 / 255, blue: 16 / 255, alpha: 0.3)
        cell.chartView.layer.cornerRadius = 15
        cell.chartView.clipsToBounds = true
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
            cell.processLabel.text = "No Data"
            cell.processLabel.alpha = 0.6
        }
        
        
        
        
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 250
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        print("row is select: \(row) in section: \(indexPath.section)")
        print(indexPath)
        
    }
    
    
    
    
    
//video
    func playBackVideo(url: NSURL, questionIndex: Int) {
        
        
        
        if let VC = self.storyboard?.instantiateViewControllerWithIdentifier("PlaybackView") as? PlaybackViewController {
            VC.url = url
            VC.questionIndex = questionIndex
            if let navi = self.navigationController {
                navi.pushViewController(VC, animated: true)
            }
        }
        
        
    }
    
    
//button
    
    @IBAction func playButtonTouchDown(sender: AnyObject) {
        print("play button touch down: \(sender.tag)")
        let row = sender.tag
        
        
    }
    
    
    
    @IBAction func playButtonTouch(sender: AnyObject) {
        if let row = sender.tag {
            print("play button touch down")
            
            
            
            //process video
            if Singleton.sharedInstance.questions[row].file.isProcess {
                //aready process before
                if let url = Singleton.sharedInstance.questions[row].file.assetURL {
                    self.playBackVideo(url, questionIndex: row)
                }
            }else {
                //animate
                self.startAnimateBarPlot(NSIndexPath(forRow: row, inSection: 0))
                //start to process
                Singleton.sharedInstance.videoComposeWithQuestion(row)
            }
            
            
            
            
            
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
    
    
    
//animation
    func startAnimateBarPlot(indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? RecordTableViewCell {
                print("start animation")
                //label
                
                cell.playButton.enabled = false
                UIView.animateWithDuration(0.8, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    cell.processLabel.alpha = 1
                    
                    }, completion: { (bool) -> Void in
                        
                })
                
                //opacity animation
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0
                animation.toValue = 0.5
                animation.autoreverses = true
                animation.beginTime = 0.8
                animation.duration = 0.8
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                animation.repeatCount = Float.infinity
                animation.removedOnCompletion = false
                //animation.fillMode = kCAFillModeForwards
                
                if let graph = cell.hostView.hostedGraph {
                    print("animation plot")
                    let plot = graph.plotAtIndex(0) as! CPTBarPlot
                    let plot2 = graph.plotAtIndex(1) as! CPTBarPlot
                    plot.addAnimation(animation, forKey: "processAnimation")
                    plot2.addAnimation(animation, forKey: "processAnimation")
                }
            }
        }
        
    }
    
    func stopAnimateBarPlot(indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? RecordTableViewCell {
                print("stop animation")
                //label
                UIView.animateWithDuration(0.8, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn], animations: { () -> Void in
                    cell.processLabel.alpha = 0
                    }, completion: { (bool) -> Void in
                        
                })
                
                if let graph = cell.hostView.hostedGraph {
                    print("animation plot")
                    let plot = graph.plotAtIndex(0) as! CPTBarPlot
                    let plot2 = graph.plotAtIndex(1) as! CPTBarPlot
                    plot.removeAnimationForKey("processAnimation")
                    plot2.removeAnimationForKey("processAnimation")
                }
                cell.playButton.enabled = true
                self.tableView.reloadData()
                
                
            }
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
