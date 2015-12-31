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
    
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var heartImage: UIImageView!
    
    
    @IBOutlet weak var heartImageConstraintX: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    

    func setupView() {
        //button
        //self.reStartButton.layer.cornerRadius = self.reStartButton.frame.height / 2
        //self.reStartButton.clipsToBounds = true
        
        //table separator
        self.addTableSeparator()
        //to zero and wait animation
        
        //wait for animation
        self.maxLabel.alpha = 0
        self.minLabel.alpha = 0
        self.averageLabel.alpha = 0
        self.heartImage.setNeedsUpdateConstraints()
        
        //calculate percentage
        let deviation = (Singleton.sharedInstance.BPMmax - Singleton.sharedInstance.BPMmin)
        let delta = Singleton.sharedInstance.BPMAverage - Singleton.sharedInstance.BPMmin
        var xOffset = Double(self.view.frame.width / 2) - 35 //if no data, image set to mid
        if deviation > delta {
            let percent = delta / deviation
            let position = Double(self.view.frame.width - 80) * percent //offset = 70 + 70 + 70(heart image)
            xOffset = 40.0 + position - 35
            if xOffset < 70 {
                xOffset = 70
            }else if xOffset > Double(self.view.frame.width) - 70 - 70 {
                xOffset = Double(self.view.frame.width) - 70 - 70
            }
        }
        
        UIView.animateWithDuration(0.5, delay: 0.3, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            self.heartImageConstraintX.constant = CGFloat(xOffset)
            self.heartImage.layoutIfNeeded()
            
            }) { (bool) -> Void in
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                    self.maxLabel.alpha = 1
                    self.minLabel.alpha = 1
                    self.averageLabel.alpha = 1
                    }, completion: nil)
        }
        
        //background circle
        let circleBack = self.getCircleBackground(self.circleView.bounds, percent: 1, lineWidth: 7)
        self.circleView.layer.insertSublayer(circleBack, atIndex: 0)
        
        //label
        self.maxLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMmax)
        self.minLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMmin)
        self.averageLabel.text = String(format: "%.0f", Singleton.sharedInstance.BPMAverage)
        print("average label: \(Singleton.sharedInstance.BPMAverage)")
        //have record
        if let totalTruthRate = (Singleton.sharedInstance.totalTruthRate) {
            print("total truth rate: \(totalTruthRate)")
            
            
            //circle
            let circle = self.getCircleGradientLayer(self.circleView.bounds, percent: (totalTruthRate), lineWidth: 7)
            self.circleView.layer.insertSublayer(circle, atIndex: 1)
            
            
            
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
            self.truthLabel.text = "No Record"
            self.truthRateLabel.text = "0"
            
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
    
    func getCircleBackground(bound: CGRect, percent: Double, lineWidth: CGFloat) -> CALayer {
        let angle = CGFloat(percent * 2 * M_PI - M_PI / 2)
        let radius = (bound.width < bound.height) ? (bound.width / 2 - lineWidth):(bound.height / 2 - lineWidth)
        let circle = UIBezierPath(arcCenter: CGPoint(x: bound.width / 2, y: bound.height / 2), radius: radius, startAngle: CGFloat(-M_PI / 2), endAngle: angle, clockwise: true)
        
        let arc = CAShapeLayer()
        arc.path = circle.CGPath
        arc.position = CGPoint(x: 0, y: 0)
        arc.fillColor = UIColor.clearColor().CGColor
        arc.strokeColor = UIColor.grayColor().CGColor
        arc.lineWidth = lineWidth
        arc.lineCap = kCALineCapRound ; //线条拐角
        arc.lineJoin = kCALineJoinRound
        arc.opacity = 0.4
        
        /*
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = bound
        gradient.colors = [UIColor(red: 179 / 255, green: 5 / 255, blue: 19 / 255, alpha: 1.0).CGColor, UIColor(red: 202 / 255, green: 24 / 255, blue: 38 / 255, alpha: 1.0).CGColor, UIColor(red: 204 / 255, green: 233 / 255 , blue: 0, alpha: 1.0).CGColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.mask = arc
        */
        return arc
        
    }

    //table line
    func addTableSeparator() {
        let bounds = self.progressView.bounds
        
        
        //set path
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: bounds.height))
        path.addLineToPoint(CGPoint(x: bounds.width, y: bounds.height))
        
        path.stroke()
        
        //change to CALayer
        let arc = CAShapeLayer()
        arc.path = path.CGPath
        arc.lineWidth = 5
        arc.fillColor = UIColor.clearColor().CGColor
        arc.strokeColor = UIColor.purpleColor().CGColor
        arc.lineCap = kCALineCapRound ; //线条拐角
        arc.lineJoin = kCALineJoinRound
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: bounds.height)
        gradientLayer.colors = [UIColor.redColor().CGColor, UIColor.yellowColor().CGColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.mask = arc
        
        //add to view
        self.progressView.layer.insertSublayer(gradientLayer, atIndex: 0)
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
