//
//  TestViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/16.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import WatchConnectivity
import Charts
import AVFoundation

class PolyTestViewController: UIViewController, WCSessionDelegate, ChartViewDelegate, AVAudioRecorderDelegate {
    
    
    @IBOutlet weak var finishedButtonBTMConst: NSLayoutConstraint!
    
    //@IBOutlet weak var chartIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var askButtonBottomConst: NSLayoutConstraint!
    
    @IBOutlet weak var QuestionLabelTopConst: NSLayoutConstraint!
    
    @IBOutlet weak var questionLabelLeadingConst: NSLayoutConstraint!
    
    @IBOutlet weak var tutorialLabel: UILabel!
    
    @IBOutlet weak var grathView: LineChartView!
    
    @IBOutlet weak var heartImage: UIImageView!
    
    @IBOutlet weak var questionLabel: UILabel!
    
    //save data from watch
    var dataDates = [NSDate]()
    var dataValues = [Double]()
    var dataMax: Double = 0
    var dataMin: Double = 100
    var average: Double = 0
    var deviation: Double = 0
    var dataIndex = 0
    let formatter = NSDateFormatter()
    var bpm = 60
    var snapHeart = UIView()
    
    //time
    var startTime = NSDate()
    var secondTimer: NSTimer?
    var suggestTimer: NSTimer?
    //question
    var questions: [question] = []
    var isSuggesting = false
    var suggestQuestion = ["What did you eat at lunch ?", "When did you get home last night ?", "Did you go out with him/her ?", "Did you wash your hands after toilet ?", "Who did you sleep with last night ?", "What's your size ?", "When was your first time ?", "Are you virgin?"]
    
    //AV record
    var audioRecorder:AVAudioRecorder!
    var recordedAudio:RecordedAudio!
    var recordCount = 0
    
    
//flag
    var isAsking = false {
        didSet {
            if self.isAsking {
                //self.askButton.setTitle("Next", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 1, green: 0.1, blue: 243 / 255, alpha: 0.9)
                self.tutorialLabel.text = "Press to start next question"
                self.startAddXTime()
                
            }else {
                //self.askButton.setTitle("Ask!", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 80 / 255, green: 1, blue: 0, alpha: 0.9)
                self.tutorialLabel.text = "Press when you ready to ask question"
                
            }
        }
    }
    
    var showFinishedButton = false {
        didSet {
            if self.showFinishedButton {
                UIView.animateWithDuration(1, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                    self.finishedButtonBTMConst.constant += 50
                    self.view.layoutIfNeeded()
                    }) { (bool) -> Void in
                        
                }
            }
        }
    }
    
//WCSession
    let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupWCConnection()
        self.setupGraph()
        self.formatter.dateFormat = "mm:ss"
        self.showFinishedButton = false
        self.finishedButtonBTMConst.constant -= 50
        
        //setup
        self.isAsking = false
        self.questionLabel.text = "Need some hints for question ?"
        //self.chartIndicator.hidden = true
        self.setupRecorder()
        
        //layer
        self.askButton.layer.cornerRadius = self.askButton.frame.width / 2
        self.askButtonBottomConst.constant = self.view.frame.height / 4 - self.askButton.frame.height / 2
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.finishRecording()
        self.deActiveRecord()
    }
    
    
//WCSession
    func setupWCConnection() {
        if WCSession.isSupported() {
            session?.delegate = self
            session?.activateSession()
            if let isConnect = session?.reachable {
                print("session reachable: \(isConnect)")
            }
        }
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        
        print("get userInfo data: ")
        if let dics = userInfo["heartRateData"] as? [NSDate : Double] {
            //sort by time
            let dicsSort = dics.sort({ (a, b) -> Bool in
                if a.0.timeIntervalSince1970 > b.0.timeIntervalSince1970 {
                    return false
                }
                return true
            })
            print("got new heart rate data: \(dicsSort)")
            //add to grath
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                //start to plot x-axis
                self.startAddXTime()
                
                for dic in dicsSort {
                    self.dataDates.append(dic.0)
                    self.dataValues.append(dic.1)
                    self.updateGraph(dic.0, value: dic.1)
                    self.updateQuestionData(dic.0, value: dic.1)
                    
                }
            }
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print(message)
        
        // got cmd from watch
        if let cmd = message["cmd"] as? String {
            if cmd == "stop" {
                print("recieve cmd from watch: stop")
                //no question
                if self.questions.count == 0 {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.alertNoAskQuestion()
                        return
                    })
                }
                
                //stop runnung
                if isAsking {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.closeAllAnimate()
                        self.finishRecording()
                        //alert
                        self.alertStopMessage()
                    })
                }
            }else if cmd == "start" {
                //start running
                print("recieve cmd from watch: start")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.startAddXTime()
                })
            }
        }
    }
    
    
    
    func sendCMDStopWatch() {
        if self.session!.reachable {
            // going to stop
            self.closeAllAnimate()
            self.finishRecording()
            
            //send cmd to watch
            self.session?.sendMessage(["cmd" : "stop"], replyHandler: { (reply) -> Void in
                if let response = reply["cmdResponse"] as? Bool {
                    if response {
                        print("got 'stop' cmd response from watch: \(response)")
                        
                        
                    }
                }
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
            
            //segue
            self.performSegueWithIdentifier("ResultSegue", sender: self)
            
        }else {
            //unReachable, alert manually close
            self.alertStopMannualOnWatch()
            return
        }
    }
    
    
    //chart
    
    func setupGraph() {
        
        //setup grath
        self.grathView.delegate = self
        self.grathView.noDataText = ""
        self.startTime = NSDate()
        self.grathView.backgroundColor = UIColor.clearColor()
        self.grathView.descriptionText = ""
        self.grathView.descriptionTextColor = UIColor.grayColor()
        self.grathView.descriptionFont = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
        
        //axis
        
        self.grathView.getAxis(ChartYAxis.AxisDependency.Right).enabled = false
        self.grathView.leftAxis.enabled = false
        /*
        let yAxisLeft = self.grathView.getAxis(ChartYAxis.AxisDependency.Left)
        yAxisLeft.spaceTop = 20
        yAxisLeft.spaceBottom = 20
        yAxisLeft.setLabelCount(2, force: true)
        //yAxisLeft.showOnlyMinMaxEnabled = true
        yAxisLeft.drawGridLinesEnabled = false
        //modify
        yAxisLeft.drawAxisLineEnabled = false
        yAxisLeft.labelTextColor = UIColor.grayColor()
        yAxisLeft.labelFont = UIFont.systemFontOfSize(11, weight: UIFontWeightLight)
        yAxisLeft.labelPosition = .OutsideChart
        */
        
        let xAxis = self.grathView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.drawLabelsEnabled = true
        //modify
        xAxis.drawAxisLineEnabled = false
        xAxis.labelTextColor = UIColor.grayColor()
        xAxis.labelFont = UIFont.systemFontOfSize(11, weight: UIFontWeightLight)
        xAxis.labelPosition = .Bottom
        xAxis.spaceBetweenLabels = 30
        self.grathView.setVisibleXRangeMaximum(10)
        self.grathView.leftAxis.drawLimitLinesBehindDataEnabled = true
        
        //legend
        let legend = self.grathView.legend
        legend.position = .LeftOfChartInside
        legend.font = UIFont.systemFontOfSize(15, weight: UIFontWeightBold)
        legend.textColor = UIColor.grayColor()
        legend.form = .Circle
        legend.xOffset = 30
        
        // test
        /*
        self.dataString = ["1", "2", "3", "4", "5", "1", "2", "3", "4", "5", "1", "2", "3", "4", "5"]
        self.dataValues = [60, 70, 80, 90, 100, 60, 70, 80, 90, 100, 60, 70, 80, 90, 100]
        
        for value in self.dataValues {
            let dataentry = ChartDataEntry(value: value, xIndex: self.dataIndex)
            self.dataIndex++
            self.chartDataSet.addEntry(dataentry)
        }
        */
        
        //setup first data
        let chartDataSet = LineChartDataSet(yVals: [ChartDataEntry()], label: "Heart Rate (BPM)")
        
        
        let data = LineChartData(xVals: ["0:00"], dataSet: chartDataSet)
        print("setup new grath data: \(data)")
        self.grathView.data = data
        
        //layout
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.drawVerticalHighlightIndicatorEnabled = true
        chartDataSet.drawValuesEnabled = false
        chartDataSet.valueFont = UIFont.systemFontOfSize(9, weight: UIFontWeightLight)
        chartDataSet.valueTextColor = UIColor.grayColor()
        chartDataSet.lineWidth = 3
        chartDataSet.circleRadius = 5
        chartDataSet.drawCubicEnabled = true
        chartDataSet.cubicIntensity = 0.1
        chartDataSet.drawFilledEnabled = true
    }
    
    
    func updateGraph(time: NSDate, value: Double) {
         //only update data after start
        if time.timeIntervalSince1970 < self.startTime.timeIntervalSince1970 {
            return
        }
        
        print("update grath")
        self.updateMaxMinValue(value)
        
        if let data = self.grathView.data {
            //update old data
            if self.dataDates.count == 1 {
                data.removeEntryByXIndex(0, dataSetIndex: 0)
            }
            let entry = ChartDataEntry(value: value, xIndex: self.diffTimeFromStart(time))
            data.addEntry(entry, dataSetIndex: 0)
            self.grathView.notifyDataSetChanged()
            
            //limit line
            if self.dataDates.count > 3 {
                self.addStaticLine()
            }
            
            //scope
            let yRange = self.getFirstTenDataRange(self.dataValues)
            let xRange = self.getFirstTenTimeRange(self.dataDates)
            let yAxis = self.grathView.leftAxis
            yAxis.enabled = false
            yAxis.startAtZeroEnabled = false
            yAxis.customAxisMax = yRange[0]
            yAxis.customAxisMin = yRange[1]
    
            //self.grathView.setVisibleYRangeMaximum(CGFloat(yRange[0]), axis: ChartYAxis.AxisDependency.Left)
            data.dataSets[0].drawValuesEnabled = true
            self.grathView.setVisibleXRangeMaximum(xRange)
            self.grathView.moveViewToX(self.dataIndex)
            self.grathView.setScaleEnabled(true)
            self.grathView.setScaleMinima(1, scaleY: 1)
            
            
            
            
            //animate
            self.animateHeart(value)
            
        }
    }
    
    func addStaticLine() {
        
        let avg = self.getAverage(self.dataValues)
        let dev = self.getStandardDeviation(self.dataValues)
        self.grathView.leftAxis.removeAllLimitLines()
        self.addYLimitLine(avg, name: "Average")
        self.addYLimitLine(avg + dev, name: "Truth Limit")
    }
    
    func addYLimitLine(value: Double, name: String) {
        let limitLine = ChartLimitLine(limit: value, label: name)
        limitLine.lineWidth = 0.5
        limitLine.lineDashPhase = 50
        limitLine.lineDashLengths = [2]
        limitLine.valueFont = UIFont.italicSystemFontOfSize(11)
        limitLine.valueTextColor = UIColor.grayColor()
        limitLine.lineColor = UIColor.grayColor()
        self.grathView.leftAxis.addLimitLine(limitLine)
    }
    
    func addQuestionLimitLine(quest: question) {
        
        let Xindex: Double = quest.startTime.timeIntervalSinceDate(self.startTime)
        let limitline = ChartLimitLine(limit: Xindex, label: "Qestion.\(quest.questIndex)")
        limitline.labelPosition = .RightBottom
        limitline.lineColor = ChartColorTemplates.joyful()[quest.questIndex % 5]
        limitline.valueFont = UIFont.italicSystemFontOfSize(14)
        limitline.valueTextColor = UIColor.grayColor()
        limitline.lineWidth = 5
        self.grathView.xAxis.addLimitLine(limitline)
        self.grathView.animate(xAxisDuration: 0.3, easingOption: ChartEasingOption.EaseInBounce)
        if !self.showFinishedButton {
            self.showFinishedButton = true
        }
    }
    
    func updateQuestionData(time: NSDate, value: Double) {
        if self.questions.count > 0 {
            for quest in self.questions {
                
                if time.timeIntervalSinceDate(quest.startTime) > 0 && quest.endTime.timeIntervalSinceDate(time) > 0 {
                    //data is in previous time range
                    quest.dataValues.append(value)
                    quest.dataDates.append(time)
                    print("add data to Q.\(quest.questIndex)")
                    return
                }
            }
            //data is in the last time range
            self.questions[questions.count - 1].dataValues.append(value)
            self.questions[questions.count - 1].dataDates.append(time)
            print("add data to Q.\(self.questions.count)")
        }
    }
    
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        print("select chart at index: \(dataSetIndex)")
        //select chart single value
        
    }
    
    
    
//calculate
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
    
    func getFirstTenDataRange(num: [Double]) -> [Double] {
        var temp = num
        while temp.count > 10 {
            let delete = temp.count - 10
            temp.removeFirst(delete)
        }
        let max = self.getMax(temp) + 3
        let min = self.getMin(temp) - 6
        
        
        return [max, min]
    }
    
    func getFirstTenTimeRange(dates: [NSDate]) -> CGFloat {
        if dates.count <= 10 {
            return 50
        }
        var temp = dates
        if temp.count > 10 {
            let delete = temp.count - 10
            temp.removeFirst(delete)
        }
        let range: CGFloat = 5 + CGFloat((temp.last!.timeIntervalSinceDate(temp[0])))
        return range
    }
    
    func updateMaxMinValue(value: Double) {
        if value > self.dataMax {
            self.dataMax = value
        }
        if value < dataMin && value != 0 {
            self.dataMin = value
        }
    }
    
    func getAverage(nums: [Double]) -> Double {
        var total = 0.0
        //use the parameter-array instead of the global variable votes
        for vote in nums{
            total += Double(vote)
        }
        let votesTotal = Double(nums.count)
        let avg = total / votesTotal
        self.average = avg
        print("average: \(avg)")
        return avg
    }
    
    func getStandardDeviation(arr : [Double]) -> Double {
        let length = Double(arr.count)
        let avg = arr.reduce(0, combine: {$0 + $1}) / length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, combine: {$0 + $1})
        let dev = sqrt(sumOfSquaredAvgDiff / length)
        self.deviation = dev
        print("dev: \(dev)")
        return dev
    }
    
//time
    func diffTimeFromStart(newTime: NSDate) -> Int {
        let diff: Double = newTime.timeIntervalSinceDate(self.startTime)
        return Int(diff)
    }
    
    func addIndexX() {
        
        if let data = self.grathView.data {
            let diff = Int(NSDate().timeIntervalSinceDate(self.startTime)) - self.dataIndex
            for var i = 0; i < diff + 2; i++ {
                self.dataIndex++
                //var timeString = self.formatter.stringFromDate(self.dataIndex)
                var timeText = NSDateComponentsFormatter().stringFromTimeInterval(Double(self.dataIndex))!
                if self.dataIndex < 10 {
                    timeText = "0:0" + timeText
                }else if self.dataIndex < 60 {
                    timeText = "0:" + timeText
                }
                
                data.addXValue(timeText)
            }
            self.grathView.notifyDataSetChanged()
            self.grathView.reloadInputViews()
        }
        
    }
    
    func startAddXTime() {
        if self.secondTimer == nil {
            self.secondTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("addIndexX"), userInfo: nil, repeats: true)
        }
    }
    
    func stopAddIndexXTime() {
        self.secondTimer?.invalidate()
        self.secondTimer = nil
    }
    
//animate
    func animateHeart(bpm: Double) {

        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        self.snapHeart = self.heartImage.snapshotViewAfterScreenUpdates(true)
        self.snapHeart.frame = self.heartImage.frame
        self.view.addSubview(self.snapHeart)
        
        var scale: Double = 1.2
        var duration = 30 / bpm
        
        //bonus heart size
        if bpm > self.average && self.dataDates.count > 3 {
            scale = 1.2 + (bpm - self.average) * 0.02
            if bpm > self.average + self.deviation {
                duration = 0.2
            }
        }
        
        if bpm > 0 {
            UIView.animateWithDuration(duration, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.Repeat], animations: { () -> Void in
                
                self.snapHeart.transform = CGAffineTransformMakeScale(CGFloat(scale), CGFloat(scale))
                }) { (Bool) -> Void in
                    
            }
        }
    }
    
    func startAnimateSuggestion() {
        print("suggestion animate")
        if self.suggestTimer == nil {
            self.animateSuggestion()
            self.isSuggesting = true
            //start suggest
            self.suggestTimer = NSTimer.scheduledTimerWithTimeInterval(8, target: self, selector: Selector("animateSuggestion"), userInfo: nil, repeats: true)
        }
    }
    
    func stopAnimateSuggestion() {
        self.isSuggesting = false
        self.suggestTimer?.invalidate()
        self.suggestTimer = nil
    }
    
    func animateSuggestion() {
        
        let randomIndex = Int(arc4random_uniform(UInt32(self.suggestQuestion.count)))
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            self.questionLabelLeadingConst.constant -= 300
            self.view.layoutIfNeeded()
            
            }) { (bool) -> Void in
                //
                self.questionLabel.text = self.suggestQuestion[randomIndex]
                
                
                
        }
        UIView.animateWithDuration(0.5, delay: 1, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.questionLabel.alpha = 1
            self.questionLabelLeadingConst.constant += 300
            self.view.layoutIfNeeded()
            }) { (bool) -> Void in
                
        }
        
    }
    
    func animateVibrate() {
        //vibrate
        
        //noise
    }
    
    func closeAllAnimate() {
        //save last question time
        self.stopAnimateSuggestion()
        self.stopAddIndexXTime()
        //self.chartIndicator.stopAnimating()
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        self.isAsking = false
    }
    
//alert
    func alertNoAskQuestion() {
        print("alert no question ask")
        let alert = UIAlertController(title: "Alert", message: "Program is stop by iWatch, you didn't ask any question.", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("test is stop by watch, jump to result", terminator: "")
                //segue
                self.navigationController?.popViewControllerAnimated(true)
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertStopMessage() {
        print("alert message: stop")
        let alert = UIAlertController(title: "Alert", message: "Program is stop by iWatch", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("test is stop by watch, jump to result", terminator: "")
                //segue
                self.performSegueWithIdentifier("ResultSegue", sender: self)
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertStopMannualOnWatch() {
        print("alert message: stop mannully")
        let alert = UIAlertController(title: "Alert", message: "Press 'Stop' button on your iWatch", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
//voice recorder
    func setupRecorder() {
        
        //Create a session
        let session = AVAudioSession.sharedInstance()
        do {
            print("setup recorder")
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
            try session.setActive(true)
            session.requestRecordPermission({ (bool) -> Void in
                if bool {
                    //allow to record
                    print("User allow to record")
                }else {
                    //not allow to record
                    print("User is not allow to record")
                }
            })
        }catch {
            //fail to record
            print("Erroe: can't setup record.")
            return
        }
    }
    
    func deActiveRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            print("de-Active recorder")
            try session.setActive(false)
            
        }catch {
            //fail to record
            print("Erroe: can't de-Active record.")
            return
        }
    }
    
    func getNewFileURL() -> NSURL {
        //Get the place to store the recorded file in the app's memory
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as String
        
        //Name the file with date/time to be unique
        let currentDateTime = NSDate();
        let formatter = NSDateFormatter();
        formatter.dateFormat = "ddMMyyyy-HHmmss";
        let recordingName = formatter.stringFromDate(currentDateTime)+".m4a"
        let pathArray = [dirPath, recordingName]
        return NSURL.fileURLWithPathComponents(pathArray)!
    }
    
    func startRecord() {
        //Create a new audio recorder
        let newURL = self.getNewFileURL()
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            //start
            print("start record new voice")
            self.audioRecorder = try AVAudioRecorder(URL: newURL, settings: settings)
            self.audioRecorder.delegate = self
            self.audioRecorder.prepareToRecord()
            self.audioRecorder.record()
        } catch {
            //error
            print("record error: can't start record")
            finishRecording()
            return
        }
        
        
    }
    
    func finishRecording() {
        if self.audioRecorder != nil {
            //updat end time of quest
            self.questions[self.questions.count - 1].endTime = NSDate()
            
            print("stop recording...")
            self.audioRecorder.stop()
            self.audioRecorder = nil
            
            
        }
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            //save to record array
            let recordedAudio = RecordedAudio()
            recordedAudio.URL = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            self.questions[self.recordCount].recordAudio = recordedAudio
            print("record stop, save to quest.\(self.recordCount + 1)")
            self.recordCount++
            
        }else {
            //fail to record
            print("Did finished recording: fail")
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
        if segue.identifier == "ResultSegue" {
            if let VC = segue.destinationViewController as? ResultViewController {
                VC.BPMAverage = self.average
                VC.BPMDeviation = self.deviation
                VC.BPMmax = self.dataMax
                VC.BPMmin = self.dataMin
                VC.questions = self.questions
            }
        }
    }
   
    
    @IBOutlet weak var askButton: UIButton!
    
    @IBAction func askButtonTouch(sender: AnyObject) {
        
        print("ask button touch")
        if self.isAsking == false {
            self.isAsking = true
            //start first question
            var quest = question()
            quest.questIndex = self.questions.count + 1
            self.questions.append(quest)
            self.startRecord()
            self.addQuestionLimitLine(quest)
            
        }else {
            //next ask question
            let quest = self.questions[self.questions.count - 1]
            quest.endTime = NSDate()
            self.finishRecording()
            
            //add next question
            let nextQuest = question()
            nextQuest.questIndex = self.questions.count + 1
            self.questions.append(nextQuest)
            self.startRecord()
            self.addQuestionLimitLine(nextQuest)
        }
        
        
        
    }
    
    @IBOutlet weak var finishedButton: UIButton!
    
    @IBAction func finishedButtonTouch(sender: AnyObject) {
        print("finished button touch")
        //had been finished before
        if self.isAsking == false {
            self.performSegueWithIdentifier("ResultSegue", sender: self)
            return
        }
        
        //going to stop, send stop message to watch
        self.sendCMDStopWatch()
        
        
    }
    
    @IBAction func suggestLabelTouch(recognizer:UITapGestureRecognizer) {
        print("tap on suggest label")
        if self.isSuggesting {
            self.animateSuggestion()
        }else {
            self.startAnimateSuggestion()
        }
    }
    
    
}
