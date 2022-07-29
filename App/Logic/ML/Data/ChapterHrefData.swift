//
//  ChapterHrefData.swift
//  Mangos
//
//  Created by Brad Guerrero on 1/3/21.
//

import Foundation

class ChapterHrefData : HrefData {
    // ML Data
    var isChapter = false
    var isChildLink = false
    var similarityRatio = 0.0
    var containsChapter = false
    var endsWithNumber = false
    
    // Metadata
    var compareLink = String()
}
