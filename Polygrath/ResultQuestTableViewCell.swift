//
//  ResultQuestTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/26.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit


class ResultQuestTableViewCell: UITableViewCell {

    
    
    @IBOutlet weak var numLabel: UILabel!
    
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    @IBOutlet weak var maxLabel: UILabel!
    
    @IBOutlet weak var minLabel: UILabel!
  
    @IBOutlet weak var warningSightView: UIImageView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
