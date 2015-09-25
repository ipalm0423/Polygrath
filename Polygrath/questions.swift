//
//  questions.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/25.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import Foundation

struct heartStatus {
    var icon = ""
    var description = "Mid-range"
    var bpm = 80
    var duration: Double {
        return 60.0 / Double(bpm)
    }
}

class question {
    var startTime = NSDate()
    var endTime = NSDate()
    var questIndex = 0
    var dataDates = [NSDate]()
    var dataValues = [Double]()
}