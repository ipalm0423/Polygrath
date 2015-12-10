//
//  RecordTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/22.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import Charts

class RecordTableViewCell: UITableViewCell, ChartViewDelegate {

    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var truthLabel: UILabel!
    
    @IBOutlet weak var questionNoLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var avgLabel: UILabel!
    
    
    @IBOutlet weak var heartImageView: UIImageView!
    
    @IBOutlet weak var forwardButton: UIButton!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    
    @IBOutlet weak var chartView: BarChartView!
    
    
    
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
    
    var grathData = BarChartData()
    
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
    }
    
    
}
