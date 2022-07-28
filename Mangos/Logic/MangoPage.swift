//
//  MangoPage.swift
//  Mangos
//
//  Created by Brad Guerrero on 5/14/20.
//  Copyright © 2020 Brad Guerrero. All rights reserved.
//

import Foundation
import UIKit

// Data that describes a runtime page of manga.
class MangoPage {
    var imgSrcUrl = String()
    var uiImage = UIImage()
    var isLoaded = false
    
    init(imgSrcUrl: String = String(), uiImage: UIImage = UIImage()) {
        self.imgSrcUrl = imgSrcUrl
        self.uiImage = uiImage
    }
}
