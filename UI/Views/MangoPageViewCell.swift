//
//  PageCollectionCell.swift
//  Mangos
//
//  Created by Brad Guerrero on 5/12/20.
//  Copyright © 2020 Brad Guerrero. All rights reserved.
//

import Foundation
import UIKit

class MangoPageViewCell : UICollectionViewCell {
    
    static let mangoPageViewCellReuseId = "MangoPageViewCell"
    
    @IBOutlet weak var imageScrollView: ImageScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
}
