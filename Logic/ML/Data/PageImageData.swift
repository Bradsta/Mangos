//
//  PageImageData.swift
//  Mangos
//
//  Created by Brad Guerrero on 1/6/21.
//

import Foundation

class PageImageData : ImgData {
    // ML Data
    var isPageImage = false
    var similarityRatio = 0.0
    var isRelatedLink = false
    var containsHost = false
    var isJPG = false
    var hasNumericName = false
    
    // Metadata
    var compareLink = String()
}
