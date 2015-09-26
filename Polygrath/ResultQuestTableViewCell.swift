//
//  ResultQuestTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/26.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class ResultQuestTableViewCell: UITableViewCell {

    
    @IBOutlet weak var processBar: UIProgressView!
    
    @IBOutlet weak var numLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
