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
        
        //circle
        let totalTruthRate = (Singleton.sharedInstance.totalTruthRate)
        let circle = self.getCircleGradientLayer(self.circleView.bounds, percent: (1 - totalTruthRate), lineWidth: 5)
        self.circleView.layer.insertSublayer(circle, atIndex: 0)
        
        //text
        self.truthRateLabel.text = String(format: "%.0f", totalTruthRate)
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
    

    
//button
    
    @IBAction func reStartButtonTouch(sender: AnyObject) {
        print("re-start button touch")
        //back to restart, don't save anything
        let count = self.navigationController!.viewControllers.count
        if let switchViewController = self.navigationController?.viewControllers[count - 3] as? VideoTestViewController {
            self.navigationController?.popToViewController(switchViewController, animated: true)
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
