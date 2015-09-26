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

class PolyTestViewController: UIViewController, WCSessionDelegate, ChartViewDelegate {
    
    
    @IBOutlet weak var finishedButtonBTMConst: NSLayoutConstraint!
    
    @IBOutlet weak var chartIndicator: UIActivityIndicatorView!
    
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
    //question
    var questions: [question] = []
    var sugestQuestion = ["What did you eat at lunch ?", "When did you get home last night ?", "Did you go out with him/her ?", "Did you wash your hands after toilet ?", "Who did you sleep with last night ?", "What's your size ?", "When was your first time ?", "Are you virgin?"]
    
//flag
    var isAsking = false {
        didSet {
            if self.isAsking {
                self.askButton.setTitle("Next", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 1, green: 0.1, blue: 243 / 255, alpha: 0.9)
                self.tutorialLabel.text = "Press to start next question"
                self.startAddXTime()
                
            }else {
                self.askButton.setTitle("Ask!", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 80 / 255, green: 1, blue: 0, alpha: 0.9)
                self.tutorialLabel.text = "Press, when you ready to ask question)"
                
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
        self.chartIndicator.startAnimating()
        
        //layer
        self.askButton.layer.cornerRadius = self.askButton.frame.width / 2
        self.askButtonBottomConst.constant = self.view.frame.height / 4 - self.askButton.frame.height / 2
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                //stop runnung
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.closeAllAnimate()
                    //alert
                    self.alertStopMessage()
                })
                
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
            //send cmd to watch
            self.session?.sendMessage(["cmd" : "stop"], replyHandler: { (reply) -> Void in
                if let response = reply["cmdResponse"] as? Bool {
                    if response {
                        print("got 'stop' cmd response from watch: \(response)")
                        //already stop
                        self.closeAllAnimate()
                        //segue
                        self.performSegueWithIdentifier("ResultSegue", sender: self)
                        
                    }
                }
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
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
        self.grathView.descriptionText = ""
        self.startTime = NSDate()
        //self.chartDataSet.colors = [UIColor(red: 230/255, green: 125/255, blue: 34/255, alpha: 1.0)]
        
        //axis
        self.grathView.xAxis.labelPosition = .Bottom
        self.grathView.getAxis(ChartYAxis.AxisDependency.Right).enabled = false
        let yAxisLeft = self.grathView.getAxis(ChartYAxis.AxisDependency.Left)
        yAxisLeft.spaceTop = 0.1
        yAxisLeft.spaceBottom = 0.05
        yAxisLeft.setLabelCount(3, force: true)
        yAxisLeft.showOnlyMinMaxEnabled = true
        yAxisLeft.drawGridLinesEnabled = false
        let xAxis = self.grathView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.drawLabelsEnabled = true
        
        self.grathView.setVisibleXRangeMaximum(10)
        self.grathView.rightAxis.drawLimitLinesBehindDataEnabled = true
        
        
        
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
        chartDataSet.drawFilledEnabled = true
        let data = LineChartData(xVals: ["0"], dataSet: chartDataSet)
        print("setup new grath data: \(data)")
        self.grathView.data = data
        

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
            
            //scope
            let Yrange = self.dataMax - self.dataMin + 10
            let YrangeMid = Yrange / 2 + self.dataMin
            self.grathView.setVisibleYRangeMaximum(CGFloat(Yrange), axis: ChartYAxis.AxisDependency.Left)
            self.grathView.setVisibleXRangeMaximum(50)
            self.grathView.moveViewTo(xIndex: self.dataIndex, yValue: CGFloat(value), axis: ChartYAxis.AxisDependency.Left)
            
            //limit line
            if self.dataDates.count > 3 {
                self.addStaticLine()
            }
            self.grathView.setScaleEnabled(true)
            self.grathView.setScaleMinima(1, scaleY: 1)
            
            //animate
            self.animateHeart(value)
            
        }
    }
    
    func addStaticLine() {
        if self.dataIndex < 4 {
            return
        }
        let avg = self.getAverage(self.dataValues)
        let dev = self.getStandardDeviation(self.dataValues)
        self.grathView.rightAxis.removeAllLimitLines()
        self.addYLimitLine(avg, name: "Average")
        self.addYLimitLine(avg + dev, name: "Truth Limit")
    }
    
    func addYLimitLine(value: Double, name: String) {
        let limitLine = ChartLimitLine(limit: value, label: name)
        limitLine.lineWidth = 1
        self.grathView.rightAxis.addLimitLine(limitLine)
    }
    
    func addQuestionLimitLine(quest: question) {
        
        let Xindex: Double = quest.startTime.timeIntervalSinceDate(self.startTime)
        let limitline = ChartLimitLine(limit: Xindex, label: "Q.\(quest.questIndex)")
        
        limitline.lineColor = ChartColorTemplates.joyful()[quest.questIndex % 5]
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
                //let timeString = self.formatter.stringFromDate(dic.0)
                //self.dataString.append(timeString)
                data.addXValue(self.dataIndex.description)
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
    
    func animateSuggestion() {
        print("suggestion animate")
        let randomIndex = Int(arc4random_uniform(UInt32(self.sugestQuestion.count)))
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            self.questionLabelLeadingConst.constant -= 300
            self.view.layoutIfNeeded()
            
            }) { (bool) -> Void in
                //
                self.questionLabel.text = self.sugestQuestion[randomIndex]
                
                
                
        }
        UIView.animateWithDuration(0.5, delay: 1, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.questionLabel.alpha = 1
            self.questionLabelLeadingConst.constant += 300
            self.view.layoutIfNeeded()
            }) { (bool) -> Void in
                
        }
        
    }
    
    func closeAllAnimate() {
        self.stopAddIndexXTime()
        self.chartIndicator.stopAnimating()
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        self.isAsking = false
    }
    
//alert
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
//struct
    
    
    
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
            self.addQuestionLimitLine(quest)
            
        }else {
            //next ask question
            var quest = self.questions[self.questions.count - 1]
            quest.endTime = NSDate()
            //add next question
            var nextQuest = question()
            nextQuest.questIndex = self.questions.count + 1
            self.questions.append(nextQuest)
            self.addQuestionLimitLine(nextQuest)
        }
        
        
        
    }
    
    @IBOutlet weak var finishedButton: UIButton!
    
    @IBAction func finishedButtonTouch(sender: AnyObject) {
        print("finished button touch")
        //close animate
        self.questions[self.questions.count - 1].endTime = NSDate()
        self.sendCMDStopWatch()
        
        //show indicate
        
        
    }
    
    
    
}
