//
//  ProfileCell.swift
//  HeatConductionInAFin
//
//  Created by Allan Jones on 5/22/15.
//  Copyright (c) 2015 Allan Jones. All rights reserved.
//

import UIKit

class ProfileCell: UITableViewCell {
    
    @IBOutlet weak var segmentNumber: UILabel!    
    @IBOutlet weak var segmentTemp: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
