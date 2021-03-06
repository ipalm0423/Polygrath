//
//  ResultViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/25.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import Charts
import AVFoundation
import AVKit
import FBSDKShareKit

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChartViewDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var minLabel: UILabel!
    
    @IBOutlet weak var avgLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var grathView: LineChartView!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //question
    var questions = [question]()
    var BPMmax: Double = 0
    var BPMmin: Double = 0
    var BPMAverage: Double = 0
    var BPMDeviation: Double = 0
    var seletedRow = 0
    //audio
    var audioPlayer:AVAudioPlayer!
    var rowInPlay = -1
    
    //grath
    var grathData = LineChartData()
    var maxXIndex = 0
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = false
        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.navigationController?.title = "Heart Rate Result"
        self.setupView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let AVP = self.audioPlayer {
            AVP.pause()
        }
    }
    
    
//setup view
    func setupView() {
        
        self.maxLabel.text = String(format: "%.0f", self.BPMmax)
        self.minLabel.text = String(format: "%.0f", self.BPMmin)
        self.avgLabel.text = String(format: "%.0f", self.BPMAverage)
        self.setupCharts(self.questions)
        self.processQuestionData(self.questions)
        
    }

    
    
    
//charts
    func setupAXisLabelCount(totalNum: Int) {
        var labelCount = 10
        while totalNum / labelCount > 10 {
            labelCount = labelCount * 2
        }
        self.grathView.xAxis.setLabelsToSkip(labelCount)
    }
    
    func setupCharts(quests: [question]) {
        
        //layout
        self.grathView.delegate = self
        self.grathView.noDataText = ""
        self.grathView.descriptionText = ""
        self.grathView.xAxis.labelPosition = .Bottom
        self.grathView.xAxis.labelPosition = .Bottom
        self.grathView.getAxis(ChartYAxis.AxisDependency.Right).enabled = false
        let yAxisLeft = self.grathView.getAxis(ChartYAxis.AxisDependency.Left)
        yAxisLeft.spaceTop = 10
        yAxisLeft.spaceBottom = 10
        yAxisLeft.setLabelCount(3, force: true)
        yAxisLeft.showOnlyMinMaxEnabled = true
        yAxisLeft.drawGridLinesEnabled = false
        yAxisLeft.axisMaximum = Double(Int(self.BPMmax + 5))
        yAxisLeft.axisMinimum = Double(Int(self.BPMmin - 5))
        
        let xAxis = self.grathView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.drawLabelsEnabled = true
        
        self.grathView.drawMarkers = false
        
        
        //data input
        var qIndex = 0
        var newDataSet = LineChartDataSet()
        
        for quest in quests {
            //input value
            qIndex++
            if quest.dataDates.count > 0 {
                var i = 0
                var dataEntries = [ChartDataEntry]()
                for value in quest.dataValues {
                    let xIndex: Int = Int(quest.dataDates[i].timeIntervalSinceDate(quest.startTime))
                    dataEntries.append(ChartDataEntry(value: value, xIndex: xIndex))
                    i++
                    if maxXIndex < xIndex {
                        maxXIndex = xIndex + 1
                    }
                }
                
                //input set
                newDataSet = LineChartDataSet(yVals: dataEntries, label: "Q.\(qIndex)")
                //set layout
                newDataSet.setColor(ChartColorTemplates.joyful()[qIndex % 5])
                newDataSet.setCircleColor(ChartColorTemplates.joyful()[qIndex % 5])
                newDataSet.circleRadius = 5
                newDataSet.lineWidth = 3
                newDataSet.drawCircleHoleEnabled = false
                newDataSet.drawValuesEnabled = false
            }else {
                //no data in this question
                newDataSet = LineChartDataSet(yVals: [ChartDataEntry(value: 0, xIndex: 0)], label: "Q.\(qIndex)")
            }
            
            
            //input
            self.grathData.addDataSet(newDataSet)
            
        }
        //add x value
        for var l = 0 ; l < maxXIndex + 1; l++ {
            self.grathData.addXValue(l.description)
        }
        //final input
        self.grathView.data = self.grathData
        
        //animate
        let yRange = self.BPMmax - self.BPMmin + 20
        let yTarget = (yRange / 2) + self.BPMmin - 10
        self.grathView.setVisibleYRangeMaximum(CGFloat(yRange), axis: ChartYAxis.AxisDependency.Left)
        self.grathView.moveViewToY(CGFloat(yTarget), axis: ChartYAxis.AxisDependency.Left)
        
    }
    

//animate
    func animateIndicator(row: Int) {
        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as? ResultQuestTableViewCell {
            cell.numLabel.hidden = true
            cell.playIndicator.hidden = false
            cell.playIndicator.startAnimating()
        }
    }
    
    func stopAnimatePlayIndicator() {
        let row = self.rowInPlay
        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as? ResultQuestTableViewCell {
            print("stop animate playIndicator: \(row)")
            cell.playIndicator.stopAnimating()
            cell.playIndicator.hidden = true
            cell.numLabel.hidden = false
        }
    }
    
    func animateSpotlightLine(lineNumber: Int) {
        //reload to oringinal data
        self.grathView.data = self.grathData
        self.grathView.xAxis.resetLabelsToSkip()
        self.grathView.notifyDataSetChanged()
        self.grathView.animate(xAxisDuration: 0.1)
        
        if let dataSets = self.grathView.data?.dataSets as? [LineChartDataSet] {
            print("select row at \(lineNumber)")
            
            for var i = 0; i < self.questions.count; i++ {
                if i == lineNumber {
                    let visibleSet = dataSets[i]
                    let color = (ChartColorTemplates.joyful())[(i + 1) % 5]
                    visibleSet.lineWidth = 3
                    visibleSet.drawFilledEnabled = true
                    visibleSet.fillColor = color
                    //circle
                    visibleSet.drawCirclesEnabled = true
                    visibleSet.drawCircleHoleEnabled = false
                    visibleSet.setColor(color)
                    visibleSet.setCircleColor(color)
                    visibleSet.circleRadius = 7
                    //value
                    visibleSet.drawValuesEnabled = true
                    
                    
                    
                }else {
                    let unVisibleSet = dataSets[i]
                    unVisibleSet.setColor(UIColor.grayColor())
                    unVisibleSet.lineWidth = 0.5
                    unVisibleSet.drawCirclesEnabled = false
                    unVisibleSet.drawValuesEnabled = false
                    unVisibleSet.drawFilledEnabled = false
                    
                }
            }
            self.grathView.notifyDataSetChanged()
            self.grathView.reloadInputViews()
        }
    }
        
    func animateTimeTrendOfLine(lineNumber: Int) {
        
        let quest = self.questions[lineNumber]
        var values = self.questions[lineNumber].dataValues
        var dates = self.questions[lineNumber].dataDates
        
        print("animate time trend for: \(quest.endTime.timeIntervalSinceDate(quest.startTime)) seconds")
        
        if dates.count > 1 {
            //add oringinal point for time compensation
            dates.insert(quest.startTime, atIndex: 0)
            values.insert(quest.dataValues[0], atIndex: 0)
            dates.append(quest.endTime)
            values.append(quest.dataValues.last!)
            
            var dataEntries = [ChartDataEntry]()
            //input data by 1/10 seconds
            for var i = 0; i < values.count - 1; i++ {
                let startTime = Int(dates[i].timeIntervalSinceDate(quest.startTime) * 10)
                let period = Int(dates[i + 1].timeIntervalSinceDate(dates[i]) * 10)
                let delta = (values[i + 1] - values[i]) / Double(period) //去小數點
                for var j = 0; j < period; j++ {
                    let value = values[i] + (Double(j) * delta)
                    let entry = ChartDataEntry(value: value, xIndex: startTime + j)
                    dataEntries.append(entry)
                }
            }
            
            //input last entry
            let totalTime = quest.endTime.timeIntervalSinceDate(quest.startTime)
            let totalXIndex = Int(totalTime * 10)
            let lastEntry = ChartDataEntry(value: quest.dataValues.last!, xIndex: totalXIndex)
            dataEntries.append(lastEntry)
            
            //xAxis
            var xAxis = [String]()
            for var i = 0; i < (totalXIndex + 10); i++ {
                xAxis.append(String(format: "%.0f", (Double(i) / 10)))
            }
            
            //input set
            let newDataSet = LineChartDataSet(yVals: dataEntries, label: "Q.\(quest.questIndex)")
            //set layout
            let color = (ChartColorTemplates.joyful())[(lineNumber + 1) % 5]
            newDataSet.setColor(color)
            newDataSet.fillColor = color
            newDataSet.drawFilledEnabled = true
            newDataSet.drawCirclesEnabled = false
            newDataSet.drawValuesEnabled = false
            newDataSet.lineWidth = 3
            
            self.grathView.data = LineChartData(xVals: xAxis, dataSet: newDataSet)
            self.setupAXisLabelCount(totalXIndex)
            self.grathView.animate(xAxisDuration: totalTime, easingOption: ChartEasingOption.Linear)
        }
    }
    
    
    
//table
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.questions.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("QuestCell") as! ResultQuestTableViewCell
        let quest = self.questions[indexPath.row]
        cell.playIndicator.hidden = true
        cell.numLabel.text = (indexPath.row + 1).description
        cell.maxLabel.text = Int(quest.max).description
        cell.minLabel.text = Int(quest.min).description
        let timeText = Singleton.sharedInstance.getTimeString(quest.startTime, stopTime: quest.endTime)
        cell.playButton.setTitle(timeText, forState: UIControlState.Normal)
        cell.warningSightView.hidden = true
        cell.playButton.tag = indexPath.row
        cell.moreButton.tag = indexPath.row
        
        //if data is enough
        if quest.isTruth != nil {
            //set color
            cell.progressBar.tintColor = ChartColorTemplates.joyful()[(indexPath.row + 1) % 5]
            
            //enough
            cell.scoreLabel.text = String(format: "%.0f", quest.score * 100) + "%"
            if quest.score > 1 {
                // prevent from infinite
                cell.progressBar.setProgress(1, animated: true)
                cell.scoreLabel.text = "100%"
            }else {
                if quest.score < 0.5 {
                    cell.warningSightView.hidden = false
                }
                cell.progressBar.setProgress(Float(quest.score), animated: true)
            }
            
        }else {
            //no enough data to analysis
            cell.progressBar.setProgress(1, animated: false)
            cell.progressBar.progressTintColor = UIColor.grayColor()
            cell.scoreLabel.text = "-"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("TitleCell") as! TitleTableViewCell
            
            return cell
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("select table row: \(indexPath.row)")
        
        
        
        
        
        
        /*audio
        //stop previous AV
        if self.audioPlayer != nil {
            if self.audioPlayer.playing {
                self.audioPlayer.stop()
                self.stopAnimatePlayIndicator()
            }
        }
        //hight light
        self.animateSpotlightLine(indexPath.row)
        */
        
        
        
    }
    
    
//audio play
    
    func playBackAudioRecord(No: Int) {
        do {
            self.stopAnimatePlayIndicator()
            try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.questions[No].file.URL, fileTypeHint: "m4a")
            self.audioPlayer.delegate = self
            self.audioPlayer.volume = 1.0
            self.audioPlayer.prepareToPlay()
            self.audioPlayer.play()
            print("playback question.\(No), duration: \(self.audioPlayer.duration)")
            self.rowInPlay = No
            self.animateIndicator(No)
        }catch {
            print("can't playback Question.\(No)")
        }
        
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("play did finished")
        self.stopAnimatePlayIndicator()
    }
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        print("play begin interruption")
        if self.audioPlayer != nil {
            self.audioPlayer.pause()
            
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
        print("play end interruption")
        if self.audioPlayer != nil {
            if !self.audioPlayer.playing {
                self.audioPlayer.play()
                
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
//video play
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
    
//calculate
    func getAverage(nums: [Double]) -> Double {
        var total = 0.0
        //use the parameter-array instead of the global variable votes
        for vote in nums{
            total += Double(vote)
        }
        let votesTotal = Double(nums.count)
        let avg = total / votesTotal
        print("average: \(avg)")
        return avg
    }
    
    func getStandardDeviation(num : [Double]) -> Double {
        let length = Double(num.count)
        let avg = num.reduce(0, combine: {$0 + $1}) / length
        let sumOfSquaredAvgDiff = num.map { pow($0 - avg, 2.0)}.reduce(0, combine: {$0 + $1})
        let dev = sqrt(sumOfSquaredAvgDiff / length)
        
        return dev
    }
    
    func getMin(values: [Double]) -> Double {
        var min:Double = 200
        for value in values {
            if value < min && value != 0 {
                min = value
            }
        }
        return min
    }
    
    func getMax(values: [Double]) -> Double {
        var max:Double = 0
        for value in values {
            if value > max {
                max = value
            }
        }
        return max
    }
    
    func getScore(values: [Double]) -> Double {
        
        let avg = self.getAverage(values)
        //let max = self.getMax(values)
        //let min = self.getMin(values)
        let dev = self.getStandardDeviation(values)
        let T = 5.0
        
        
        var score: Double = T / (3 * dev)
        
        if avg > self.BPMAverage + 0.2 * self.BPMDeviation {
            score = score * 0.8
        }
        return score
    }
    
    
    func processQuestionData(quests: [question]) {
        print("process data")
        for quest in quests {
            if quest.dataValues.count > 0 {
                //find min
                quest.max = self.getMax(quest.dataValues)
                //find max
                quest.min = self.getMin(quest.dataValues)
                //find average
                quest.average = self.getAverage(quest.dataValues)
                //find score
                quest.score = self.getScore(quest.dataValues)
                quest.isTruth = quest.score > 0.6 ? true : false
                
            }else {
                //no data to process
                quest.isTruth = nil
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaySegue" {
            
        }
    }
    
    
//button click

    @IBAction func PlayButtonTouch(sender: AnyObject) {
        if let row = sender.tag {
            //play back video
            self.playBackVideo(self.questions[row].file.URL)
            
            
            /*
            //pause if start
            if row == self.rowInPlay {
                if let AV = self.audioPlayer {
                    if AV.playing {
                        AV.pause()
                        self.stopAnimatePlayIndicator()
                        return
                    }
                }
            }
            
            print("press play button on row: \(row)")
            self.playBackAudioRecord(row)
            self.animateTimeTrendOfLine(row)
            */
        }

    }
    
    
    @IBAction func moreButtonTouch(sender: AnyObject) {
        if let row = sender.tag {
            print("press play button on row: \(row)")
            let alert = UIAlertController(title: "Share Video", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            //camera roll
            let actionSaveToCamera = UIAlertAction(title: "Save to Camera Roll", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                print("save question.\(row) to camera roll")
                let url = self.questions[row].file.URL
                Singleton.sharedInstance.saveVideoToCameraRoll(url, completion: { (identifier, newUrl) -> Void in
                    self.questions[row].file.assetURL = newUrl
                })
            })
            
            //facebook
            let actionShareFB = UIAlertAction(title: "Facebook", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                print("share question.\(row) to facebook")
                
                if let assetUrl = self.self.questions[row].file.assetURL {
                    //already save to camera roll
                    Singleton.sharedInstance.shareVideoToFacebook(assetUrl, targetVC: self)
                }else {
                    //save to camera roll first
                    let url = self.questions[row].file.URL
                    Singleton.sharedInstance.shareVideoToFacebookAndCameraRoll(url, targetVC: self, completion: { (newURL) -> Void in
                        self.questions[row].file.assetURL = newURL
                    })
                }
                
            })
            
            //messenger
            let actionShareMessenger = UIAlertAction(title: "Messenger", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                print("share question.\(row) to Messenger")
                let url = self.questions[row].file.URL
                if let assetUrl = self.self.questions[row].file.assetURL {
                    //already save to camera roll
                    Singleton.sharedInstance.shareVideoToMessenger(url)
                }else {
                    //save to camera roll first
                    Singleton.sharedInstance.shareVideoToMessengerAndCameraRoll(url, completion: { (newURL) -> Void in
                        self.questions[row].file.assetURL = newURL
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
    }
    
    
    
    
    
    
}
