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
    var dataString = [String]()
    var dataValues = [Double]()
    var dataMax: Double = 0
    var dataMin: Double = 100
    var average: Double = 0
    var deviation: Double = 0
    var chartDataSet = LineChartDataSet(yVals: [], label: "Heart Rate (BPM)")
    var dataIndex = 0
    let formatter = NSDateFormatter()
    var bpm = 60
    var snapHeart = UIView()
    
    //time
    var startTime = NSDate()
    
    //question
    var questions: [question] = []
    var sugestQuestion = ["What did you eat at lunch ?", "When did you get home last night ?", "Did you go out with him/her ?", "Did you wash your hands after toilet ?", "Who did you sleep with last night ?", "What's your size ?", "When was your first time ?", "Are you virgin?"]
    
    //flag
    var isAsking = false {
        didSet {
            if self.isAsking {
                self.askButton.setTitle("End", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 1, green: 0.1, blue: 243 / 255, alpha: 0.9)
                self.tutorialLabel.text = "Press, when question no.\(self.questions.count) had been answerd."
            }else {
                self.askButton.setTitle("Ask!", forState: UIControlState.Normal)
                self.askButton.backgroundColor = UIColor(red: 80 / 255, green: 1, blue: 0, alpha: 0.9)
                self.tutorialLabel.text = "Press, when you ready to ask question no.\(self.questions.count + 1)"
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
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        
        if let dics = message["heartRateData"] as? [NSDate : Double] {
            print("got data", terminator: "")
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                for dic in dics {
                    let timeString = self.formatter.stringFromDate(dic.0)
                    self.dataString.append(timeString)
                    self.dataDates.append(dic.0)
                    self.dataValues.append(dic.1)
                    self.chartIndicator.stopAnimating()
                    self.updateGraph(timeString, value: dic.1)
                    
                }
            }
        }
    }
    
    //chart
    
    func setupGraph() {
        //setup
        self.grathView.delegate = self
        self.grathView.noDataText = ""
        self.grathView.descriptionText = ""
        self.chartDataSet.drawCubicEnabled = true
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
        
        self.grathView.setVisibleXRangeMaximum(10)
        self.grathView.rightAxis.drawLimitLinesBehindDataEnabled = true
        
        
        
        
        
        // test 
        
        self.dataString = ["1", "2", "3", "4", "5", "1", "2", "3", "4", "5", "1", "2", "3", "4", "5"]
        self.dataValues = [60, 70, 80, 90, 100, 60, 70, 80, 90, 100, 60, 70, 80, 90, 100]
        
        for value in self.dataValues {
            let dataentry = ChartDataEntry(value: value, xIndex: self.dataIndex)
            self.dataIndex++
            self.chartDataSet.addEntry(dataentry)
        }
        
        
        let data = LineChartData(xVals: self.dataString, dataSet: self.chartDataSet)
        print(data)
        self.grathView.data = data
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("addXTime"), userInfo: nil, repeats: true)

    }
    
    func addXTime() {
        print("add x")
        self.grathView.data?.addXValue("1")
    }
    
    func updateGraph(time: String, value: Double) {
        print(", update grath")
        if value > self.dataMax {
            self.dataMax = value
        }
        if value < dataMin {
            self.dataMin = value
        }
        
        if let data = self.grathView.data {
            print("input grath at index: \(self.dataIndex)")
            let entry = ChartDataEntry(value: value, xIndex: self.dataIndex)
            data.addXValue(time)
            data.addEntry(entry, dataSetIndex: 0)
            self.grathView.notifyDataSetChanged()
            //scope
            let Yrange = self.dataMax - self.dataMin + 10
            self.grathView.setVisibleYRangeMaximum(CGFloat(Yrange), axis: ChartYAxis.AxisDependency.Left)
            self.grathView.setVisibleXRangeMaximum(10)
            self.grathView.moveViewTo(xIndex: self.dataIndex, yValue: CGFloat(value), axis: ChartYAxis.AxisDependency.Left)
            //limit line
            self.addStaticLine()
            self.grathView.setScaleEnabled(true)
            self.grathView.setScaleMinima(1, scaleY: 1)
            self.dataIndex++
            
            self.animateHeart(value)
        }else {
            
            let dataentry = ChartDataEntry(value: value, xIndex: self.dataIndex)
            self.chartDataSet.addEntry(dataentry)
            let data = LineChartData(xVals: self.dataString, dataSet: self.chartDataSet)
            self.grathView.data = data
            self.grathView.notifyDataSetChanged()
            //scope
            let Yrange = self.dataMax - self.dataMin + 10
            self.grathView.setVisibleYRangeMaximum(CGFloat(Yrange), axis: ChartYAxis.AxisDependency.Left)
            self.grathView.moveViewTo(xIndex: self.dataIndex, yValue: CGFloat(value), axis: ChartYAxis.AxisDependency.Left)
            //limit line
            //self.addStaticLine()
            self.getAverage(self.dataValues)
            self.getStandardDeviation(self.dataValues)
            self.grathView.setScaleEnabled(true)
            self.grathView.setScaleMinima(1, scaleY: 1)
            self.dataIndex++
            
            //animate
            self.animateHeart(value)
            NSTimer.scheduledTimerWithTimeInterval(8, target: self, selector: Selector("animateSuggestion"), userInfo: nil, repeats: true)
            
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
    
    func addXLimitLine(index: Double) {
        let status = self.isAsking ? "Start" : "End"
        let limitline = ChartLimitLine(limit: index, label: "Q.\(self.questions.count) \(status)")
        limitline.lineColor = ChartColorTemplates.joyful()[self.questions.count]
        limitline.lineWidth = 10
        self.grathView.xAxis.addLimitLine(limitline)
        self.grathView.animate(xAxisDuration: 0.5, easingOption: ChartEasingOption.EaseInElastic)
    }
    
    func updateXLimitLine() {
        
    }
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        print("select chart at index: \(dataSetIndex)")
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
    
//animate
    func animateHeart(bpm: Double) {
        self.snapHeart.layer.removeAllAnimations()
        self.snapHeart.removeFromSuperview()
        self.snapHeart = self.heartImage.snapshotViewAfterScreenUpdates(true)
        self.snapHeart.frame = self.heartImage.frame
        self.view.addSubview(self.snapHeart)
        
        var scale: Double = 1.2
        var duration = 30 / bpm
        if bpm > self.average {
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
    
//struct
    struct heartStatus {
        var icon = ""
        var description = "Mid-range"
        var bpm = 80
        var duration: Double {
            return 60.0 / Double(bpm)
        }
    }
    
    struct question {
        var startTime = NSDate()
        var endTime = NSDate()
        var index = 0
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func moveViewTouch(sender: AnyObject) {
        print("touch move view")
        self.dataValues.append(88)
        self.dataString.append("")
        
        if let data = self.grathView.data {
            print("get data")
            print(self.dataIndex)
            let entry = ChartDataEntry(value: 88, xIndex: self.dataIndex)
            data.addXValue("add")
            data.addEntry(entry, dataSetIndex: 0)
            self.dataValues.append(88)
            //limit line
            self.addStaticLine()
            self.grathView.notifyDataSetChanged()
            let Yrange = 50
            print("y range = \(Yrange)")
            self.grathView.setVisibleXRangeMaximum(10)
            self.grathView.setVisibleYRangeMaximum(CGFloat(Yrange), axis: ChartYAxis.AxisDependency.Left)
            self.grathView.moveViewTo(xIndex: self.dataIndex - 10, yValue: CGFloat(88), axis: ChartYAxis.AxisDependency.Left)
            self.grathView.setScaleEnabled(true)
            self.grathView.setScaleMinima(1, scaleY: 1)
            self.dataIndex++
            
            self.animateHeart(self.dataValues[self.dataIndex - 10])
        }
        
    }
    
    @IBOutlet weak var askButton: UIButton!
    
    @IBAction func askButtonTouch(sender: AnyObject) {
        if self.isAsking == false {
            self.questions.append(question())
        }
        self.isAsking = !self.isAsking
        self.addXLimitLine(Double(self.dataIndex) - 0.5)
        
       
        
    }
    
    
}
