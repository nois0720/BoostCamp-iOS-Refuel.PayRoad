//
//  DateSelectCollectionViewCell.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 12..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

class DateSelectCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = ColorStore.lightGray
    }
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? ColorStore.skyBlue : ColorStore.lightGray
        }
    }
}
