//
//  FrontInterfaceController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/24.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import WatchKit
import Foundation


class FrontInterfaceController: WKInterfaceController {

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
    
    var animationTimer: NSTimer?
    
    override func didAppear() {
        self.startAnimate()
    }
    
    @IBOutlet var image1: WKInterfaceImage!
    
    func startAnimate() {
        self.animationTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("animatePulse"), userInfo: nil, repeats: true)
    }
    
    func stopAnimate() {
        self.animationTimer?.invalidate()
        self.animationTimer = nil
    }
    
    func animatePulse() {
        self.image1.setRelativeWidth(1.0, withAdjustment: 0.0)
        self.animateWithDuration(2) { () -> Void in
            self.image1.setRelativeWidth(0.0, withAdjustment: 0)
        }
        
        
    }
    
    
    

}
