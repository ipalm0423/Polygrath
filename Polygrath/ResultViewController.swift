//
//  ResultViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/25.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import Charts

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var minLabel: UILabel!
    
    @IBOutlet weak var avgLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var grathView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //question
    var questions = [question]()
    var BPMmax: Double = 0
    var BPMmin: Double = 0
    var BPMAverage: Double = 0
    var BPMDeviation: Double = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//setup view
    func setupView() {
        self.maxLabel.text = self.BPMmax.description
        self.minLabel.text = self.BPMmin.description
        self.avgLabel.text = self.BPMAverage.description
        self.setupCharts(self.questions)
        self.processQuestionData(self.questions)
        
    }

    
    
    
//charts
    func setupCharts(quest: [question]) {
        
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
        
        cell.numLabel.text = (indexPath.row + 1).description
        cell.timeLabel.text = String(format: "%.1f", quest.endTime.timeIntervalSinceDate(quest.startTime))
        //if data is enough
        if let result = quest.isTruth {
            //enough
            cell.scoreLabel.text = Int(quest.score * 100).description + "%"
            cell.processBar.progress = Float(quest.score)
            cell.resultLabel.text = result ? "True" : "Lie"
        }else {
            //no enough data to analysis
            cell.scoreLabel.text = ""
            cell.processBar.progress = 0
            cell.resultLabel.text = ""
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
        let max = self.getMax(values)
        let min = self.getMin(values)
        let range = max - min
        let dev = (avg - BPMAverage)
        var score: Double = range / self.BPMDeviation
        
        
        
        
        if max > self.BPMAverage + self.BPMDeviation {
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
                quest.min = self.getMax(quest.dataValues)
                //find average
                quest.average = self.getAverage(quest.dataValues)
                //find score
                quest.score = self.getScore(quest.dataValues)
                quest.isTruth = quest.score > 0.7 ? true : false
                
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

}
