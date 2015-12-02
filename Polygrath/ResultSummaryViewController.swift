//
//  ResultSummaryViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/16.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class ResultSummaryViewController: UIViewController {

    //contorl summary action
    
    
    let pageControl = 0
    
    
    
    @IBOutlet weak var truthRateLabel: UILabel!
    
    @IBOutlet weak var truthLabel: UILabel!
    
    @IBOutlet weak var reStartButton: UIButton!
    
    @IBOutlet weak var circleView: UIView!
    
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var minLabel: UILabel!
    
    @IBOutlet weak var averageLabel: UILabel!
    
    
    @IBOutlet weak var stackTableView: UIStackView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setupView() {
        //button
        self.reStartButton.layer.cornerRadius = self.reStartButton.frame.height / 2
        self.reStartButton.clipsToBounds = true
        
        //table separator
        self.addTableSeparator()
        
        //have data enough
        if let totalTruthRate = (Singleton.sharedInstance.totalTruthRate) {
            print("total truth rate: \(totalTruthRate)")
            //label
            self.maxLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMmax)
            self.minLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMmin)
            self.averageLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMAverage)
            
            //circle
            let circle = self.getCircleGradientLayer(self.circleView.bounds, percent: (1 - totalTruthRate), lineWidth: 5)
            self.circleView.layer.insertSublayer(circle, atIndex: 0)
            
            
            
            //judgement text
            self.truthRateLabel.text = String(format: "%.0f", totalTruthRate * 100)
            if totalTruthRate > 0.8 {
                self.truthLabel.text = "Honest"
            }else if totalTruthRate > 0.6 {
                self.truthLabel.text = "Something hide"
            }else if totalTruthRate > 0.4 {
                self.truthLabel.text = "Sly"
            }else if totalTruthRate > 0.2 {
                self.truthLabel.text = "Cheater"
            }else {
                self.truthLabel.text = "Big Liar"
            }
        }else {
            //no data
            self.truthLabel.text = "Not enough data"
            self.truthRateLabel.text = "0"
            self.maxLabel.text = "--"
            self.minLabel.text = "--"
            self.averageLabel.text = "--"
        }
        
        
        
    }
    
//view
    func getCircleGradientLayer(bound: CGRect, percent: Double, lineWidth: CGFloat) -> CALayer {
        let angle = CGFloat(percent * 2 * M_PI - M_PI / 2)
        let radius = (bound.width < bound.height) ? (bound.width / 2 - lineWidth):(bound.height / 2 - lineWidth)
        let circle = UIBezierPath(arcCenter: CGPoint(x: bound.width / 2, y: bound.height / 2), radius: radius, startAngle: CGFloat(-M_PI / 2), endAngle: angle, clockwise: true)
        
        let arc = CAShapeLayer()
        arc.path = circle.CGPath
        arc.position = CGPoint(x: 0, y: 0)
        arc.fillColor = UIColor.clearColor().CGColor
        arc.strokeColor = UIColor.purpleColor().CGColor
        arc.lineWidth = lineWidth
        arc.lineCap = kCALineCapRound ; //线条拐角
        arc.lineJoin = kCALineJoinRound
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = bound
        gradient.colors = [UIColor(red: 179 / 255, green: 5 / 255, blue: 19 / 255, alpha: 1.0).CGColor, UIColor(red: 202 / 255, green: 24 / 255, blue: 38 / 255, alpha: 1.0).CGColor, UIColor(red: 204 / 255, green: 233 / 255 , blue: 0, alpha: 1.0).CGColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.mask = arc
        
        return gradient
    }
    

    //table line
    func addTableSeparator() {
        let bound = self.stackTableView.bounds
        let width = self.view.frame.width - 80
        
        //set path
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: 0))
        path.addLineToPoint(CGPoint(x: width, y: 0))
        path.moveToPoint(CGPoint(x: 0, y: bound.height))
        path.addLineToPoint(CGPoint(x: width, y: bound.height - 1))
        path.stroke()
        
        //change to CALayer
        let arc = CAShapeLayer()
        arc.path = path.CGPath
        arc.lineWidth = 2
        arc.fillColor = UIColor.clearColor().CGColor
        arc.strokeColor = UIColor.purpleColor().CGColor
        arc.lineCap = kCALineCapRound ; //线条拐角
        arc.lineJoin = kCALineJoinRound
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bound
        gradientLayer.colors = [UIColor.redColor().CGColor, UIColor.yellowColor().CGColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.mask = arc
        gradientLayer.opacity = 0.8
        
        //add to view
        self.stackTableView.layer.insertSublayer(gradientLayer, atIndex: 0)
    }

    
//button
    
    @IBAction func reStartButtonTouch(sender: AnyObject) {
        print("re-start button touch")
        NSNotificationCenter.defaultCenter().postNotificationName("restartButtonTouch", object: nil)
        
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
