//
//  RecordTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/22.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var truthLabel: UILabel!
    
    @IBOutlet weak var bpmLabel: UILabel!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    @IBOutlet weak var forwardButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    
    
    
}
