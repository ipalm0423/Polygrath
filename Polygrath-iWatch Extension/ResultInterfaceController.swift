//
//  ResultInterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation


class ResultInterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        //progress data
        if let data = context as? [Double] {
            self.max = Int(self.getMax(data))
            self.min = Int(self.getMin(data))
            self.average = Int(self.getAverage(data))
            print("test result: Max:\(self.max), min: \(self.min), avg: \(self.average)")
            
        }
        
        //setup table
        self.tableOutlet.setNumberOfRows(3, withRowType: "dataRow")
        for var i = 0; i < 3; i++ {
            let row = tableOutlet.rowControllerAtIndex(i) as! RowController
            switch i {
            case 0:
                row.headLabel.setText("Max")
                row.dataLabel.setText(self.max.description)
            case 1:
                row.headLabel.setText("min")
                row.dataLabel.setText(self.min.description)
            case 2:
                row.headLabel.setText("Avg.")
                row.dataLabel.setText(self.average.description)
            default:
                print("error with table")
            }
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func didAppear() {
        self.animateHeart()
    }
    
    
    @IBOutlet var tableOutlet: WKInterfaceTable!
    
    @IBOutlet var heartImage: WKInterfaceImage!
    
    @IBOutlet var group1: WKInterfaceGroup!
    
    
    var dataValue = [Double]()
    var max = 0
    var min = 0
    var average = 0
    
    
    

    func animateHeart() {
        self.animateWithDuration(0.4) { () -> Void in
            self.heartImage.setRelativeWidth(0.3, withAdjustment: 0)
            self.group1.sizeToFitHeight()
            self.tableOutlet.setAlpha(1.0)
        }
        
        
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
    
    func getAverage(nums: [Double]) -> Double {
        var total = 0.0
        //use the parameter-array instead of the global variable votes
        for vote in nums{
            total += Double(vote)
        }
        let votesTotal = Double(nums.count)
        let avg = total / votesTotal
        
        print("calculate average: \(avg)")
        return avg
    }
    
    
    
    
}
