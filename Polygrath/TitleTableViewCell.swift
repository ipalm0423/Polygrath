//
//  TitleTableViewCell.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/9/26.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    @IBOutlet weak var column1Label: UILabel!
    
    @IBOutlet weak var column2Label: UILabel!
    
    @IBOutlet weak var column3Label: UILabel!
    
    @IBOutlet weak var column4Label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.column1Label.text = "No."
        self.column2Label.text = "Truth Score"
        self.column3Label.text = "Time"
        self.column4Label.text = "Result"
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
