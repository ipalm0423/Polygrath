//
//  Step2InterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation


class Step2InterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.stopAnimate()
    }
    
    override func didAppear() {
        self.startAnimate()
    }
    
    @IBOutlet var pushButton: WKInterfaceButton!
    
    
    @IBOutlet var group1: WKInterfaceGroup!
    
    
    var animationTimer: NSTimer?
    
    
    func startAnimate() {
        self.animationTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("animateBig"), userInfo: nil, repeats: true)
        
    }
    
    func stopAnimate() {
        self.animationTimer?.invalidate()
        self.animationTimer = nil
        
    }
    
    func animateBig() {
        print("animate big")
        self.animateWithDuration(1) { () -> Void in
            self.group1.setRelativeHeight(0.8, withAdjustment: 0)
        }
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            self.animateSmall()
        }
        
        
    }
    
    func animateSmall() {
        print("animate small")
        self.animateWithDuration(1) { () -> Void in
            self.group1.setRelativeHeight(0.65, withAdjustment: 0)
        }
    }
    

}
