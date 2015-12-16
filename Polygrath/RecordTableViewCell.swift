//
//  RecordTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/22.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
//import Charts
import CorePlot

class RecordTableViewCell: UITableViewCell, CPTBarPlotDataSource, CPTBarPlotDelegate, CPTPlotSpaceDelegate {

    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var truthLabel: UILabel!
    
    @IBOutlet weak var questionNoLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var avgLabel: UILabel!
    
    
    @IBOutlet weak var heartImageView: UIImageView!
    
    @IBOutlet weak var forwardButton: UIButton!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var chartView: UIView!
    
    
    @IBOutlet var processView: UIStackView!
    
    @IBOutlet var processIndicator: UIActivityIndicatorView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    

//Chart setup
    var quest: question! 
    var hostView = CPTGraphHostingView()
    var modifyData = [Double]()
    
    //var grathData = BarChartData()
    
    func setupPlotGraph(size: CGSize) {
        self.hostView.removeFromSuperview()
        self.hostView = CPTGraphHostingView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let graph = CPTXYGraph(frame: hostView.frame)
        self.hostView.hostedGraph = graph
        self.chartView.addSubview(self.hostView)
        print("chart view frame: \(self.chartView.frame)")
        //graph.title = "test"
        graph.backgroundColor = nil
        graph.plotAreaFrame?.masksToBorder = false
        graph.masksToBorder = false
        graph.paddingBottom = 0
        graph.paddingLeft  = 0.0
        graph.paddingTop    = 0
        graph.paddingRight  = 0.0
        
        //axis
        let axisSet = graph.axisSet as! CPTXYAxisSet
        
        //line style
        let xLineStyle = CPTMutableLineStyle()
        xLineStyle.dashPattern = [NSNumber(double: 2), NSNumber(double: 2)]
        xLineStyle.lineColor = CPTColor(componentRed: 219 / 255, green: 13 / 255, blue: 130 / 255, alpha: 0.8)
        xLineStyle.lineWidth = 2
        let textStyle = CPTMutableTextStyle()
        textStyle.fontName = "HelveticaNeue-Light"
        textStyle.fontSize = 12
        textStyle.color = CPTColor(componentRed: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 0.8)
        
        //x
        let xAxis = axisSet.xAxis!
        xAxis.majorIntervalLength = NSNumber(double: 1)
        xAxis.axisLineStyle         = xLineStyle
        xAxis.majorTickLineStyle    = nil;
        xAxis.minorTickLineStyle    = nil;
        xAxis.labelAlignment = CPTAlignment.Right
        xAxis.labelingPolicy = .None
        xAxis.labelTextStyle = textStyle
        xAxis.labelOffset = 2
        xAxis.orthogonalPosition = 0
        //xAxis.labelFormatter = nil
        
        //y
        let yAxis = axisSet.yAxis!
        yAxis.majorIntervalLength = NSNumber(double: 20)
        yAxis.axisLineStyle         = nil;
        yAxis.majorTickLineStyle    = nil;
        yAxis.minorTickLineStyle    = nil;
        yAxis.labelFormatter        = nil;
        yAxis.orthogonalPosition = 0
        
        //x label
        let count = self.quest.dataDates.count
        //let midTime = self.quest.dataDates[count / 2]
        let customTickLocations = [count + 1] //bias 1 bar width
        let xAxisLabels = [Singleton.sharedInstance.getTimeString(quest.startTime, stopTime: quest.dataDates.last!)]
        
        
        var labelLocation = 0
        var customLabels = Set<CPTAxisLabel>()
        for tickLocation in customTickLocations {
            let newLabel = CPTAxisLabel(text:xAxisLabels[labelLocation], textStyle:xAxis.labelTextStyle)
            newLabel.tickLocation = tickLocation
            newLabel.offset       = xAxis.labelOffset //+ xAxis.majorTickLength  (y direction offset)
            //newLabel.rotation     = CGFloat(M_PI_4)
            customLabels.insert(newLabel)
            labelLocation++
        }
        xAxis.axisLabels = customLabels
        
        
        
        
        //bar line
        let barLineStyle = CPTMutableLineStyle()
        barLineStyle.lineWidth = 0
        barLineStyle.lineColor = CPTColor.clearColor()
        
        
        //bar plot
        let barPlot = CPTBarPlot()
        barPlot.barWidth = 0.8
        barPlot.barsAreHorizontal = false
        //barPlot.barBaseCornerRadius = 30
        barPlot.barCornerRadius = 30
        barPlot.dataSource = self
        barPlot.delegate = self
        barPlot.identifier = "BPM"
        barPlot.barOffset = 0
        barPlot.lineStyle = barLineStyle
        
        //bar plot
        let mirrorBarPlot = CPTBarPlot()
        mirrorBarPlot.barWidth = 0.8
        mirrorBarPlot.barsAreHorizontal = false
        //barPlot.barBaseCornerRadius = 30
        mirrorBarPlot.barCornerRadius = 30
        mirrorBarPlot.dataSource = self
        mirrorBarPlot.delegate = self
        mirrorBarPlot.identifier = "BPMmirror"
        mirrorBarPlot.barOffset = 0
        mirrorBarPlot.lineStyle = barLineStyle
        
        //plot space
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = true
        plotSpace.allowsMomentumX = true
        var maxXLength = 30
        while maxXLength < self.quest.dataDates.count + 10 {
            maxXLength += 30
        }
        let xRange = CPTPlotRange(location: -0.5, length: maxXLength) //label bias -0.5 fix bar hide in idx = 0
        let BPMModify = Singleton.sharedInstance.BPMmax - (Singleton.sharedInstance.BPMmin - 10)  //bias 10
        let fullYRange = BPMModify * 2 + 20 //mirror and bias 20
        let yRange = CPTPlotRange(location: -(BPMModify + 10), length: fullYRange)
    
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        plotSpace.globalXRange = xRange
        plotSpace.globalYRange = yRange
        plotSpace.delegate = self
        
        
        graph.addPlot(barPlot, toPlotSpace: plotSpace)
        graph.addPlot(mirrorBarPlot, toPlotSpace: plotSpace)
    }
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        return UInt(self.quest.dataValues.count)
    }
    
    
    
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
        var num: [AnyObject]?
        
        switch (Int(fieldEnum)) {
        case CPTBarPlotField.BarTip.rawValue:
            let modify = self.quest.dataValues[Int(idx)] - (Singleton.sharedInstance.BPMmin - 10)
            if plot.identifier!.isEqual("BPM") {
                return NSNumber(double: modify)
            }else {
                //mirror
                return NSNumber(double: -(modify))
            }
            
        case CPTBarPlotField.BarLocation.rawValue:
            return NSNumber(unsignedInteger: idx)
            
        default:
            print("error number")
            return nil
        }
        
        
        
        
    }
    
    func barFillForBarPlot(barPlot: CPTBarPlot, recordIndex idx: UInt) -> CPTFill? {
        
        let topcolor = CPTColor(componentRed: 218 / 255, green: 24 / 255, blue: 41 / 255, alpha: 0.8)
        let bottomColor = CPTColor(componentRed: 219 / 255, green: 13 / 255, blue: 130 / 255, alpha: 0.8)
        let fillGradient = CPTGradient(beginningColor: topcolor, endingColor: bottomColor, beginningPosition: 0, endingPosition: 1)
        if barPlot.identifier!.isEqual("BPM") {
            fillGradient.angle = -90
        }else {
            fillGradient.angle = 90
        }
        
        
        return CPTFill(gradient: fillGradient)
    }
    
    func plotSpace(space: CPTPlotSpace, willDisplaceBy proposedDisplacementVector: CGPoint) -> CGPoint {
        
        
        return CGPointMake(proposedDisplacementVector.x, 0)
    }
    
    /* iOS CHARTS
    func setupChartGraph() {
        self.chartView.delegate = self
        self.chartView.noDataText = "No Data"
        self.chartView.descriptionText = ""
        self.chartView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        self.chartView.drawBordersEnabled = false
        self.chartView.drawValueAboveBarEnabled = false
        self.chartView.maxVisibleValueCount = 3
        self.chartView.dragEnabled = true
        self.chartView.scaleXEnabled = false
        self.chartView.scaleYEnabled = false
        self.chartView.pinchZoomEnabled = false
        self.chartView.doubleTapToZoomEnabled = false
        self.chartView.legend.enabled = false
        self.chartView.drawGridBackgroundEnabled = false //set to clear color
        
        let textColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 0.7)
        //x-axis
        let xAxis = self.chartView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .Bottom
        xAxis.labelFont = UIFont(name: "Helvetica-light", size: 12)!
        xAxis.labelTextColor = textColor
        //right axis
        self.chartView.getAxis(ChartYAxis.AxisDependency.Right).enabled = false
        let yAxis = self.chartView.getAxis(ChartYAxis.AxisDependency.Left)
        //y axis
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.setLabelCount(0, force: true)
        yAxis.axisMaximum = Singleton.sharedInstance.BPMmax + 5
        yAxis.axisMinimum = Singleton.sharedInstance.BPMmin - 5
        
        //bar data
        var entrys = [ChartDataEntry]()
        for var i = 0; i < quest.dataValues.count; i++ {
            entrys.append(BarChartDataEntry(value: quest.dataValues[i], xIndex: i))
        }
        let dataSet = BarChartDataSet(yVals: entrys, label: nil)
        dataSet.barSpace = 0.1
        dataSet.setColor(UIColor(red: 218 / 255, green: 26 / 255, blue: 41 / 255, alpha: 0.7))
        dataSet.barShadowColor = UIColor.clearColor()
        dataSet.valueTextColor = textColor
        dataSet.valueFont = UIFont(name: "Helvetica-light", size: 12)!
        dataSet.highLightAlpha = 0
        
        //input y data
        self.grathData.addDataSet(dataSet)
        self.chartView.data = self.grathData
        
        //input x data
        for time in quest.dataDates {
            
            let timeString = Singleton.sharedInstance.getTimeString(quest.startTime, stopTime: time)
            self.chartView.data?.addXValue(timeString)
        }
        self.chartView.backgroundColor = UIColor.clearColor()
        
        //animate
        self.chartView.animate(yAxisDuration: 1.0, easingOption: ChartEasingOption.EaseInBounce)
    }*/
    
    
}
