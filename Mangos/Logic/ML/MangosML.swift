//
//  MangosML.swift
//  Mangos
//
//  Created by Brad Guerrero on 1/3/21.
//

import Foundation
import CoreML

class MangosML {
    
    static func getChapters(chapterHrefData: [ChapterHrefData]) -> [MangoChapter] {
        var mangoChapters = [MangoChapter]()
        guard let chapterClassifier = try? MangoChapterClassifier_V3(configuration: MLModelConfiguration()) else {
            fatalError("Error in creating MangoChapterClassifier.")
        }
        
        for chapter in chapterHrefData {
            guard let prediction = try? chapterClassifier.prediction(isChildLink: String(chapter.isChildLink), similarityRatio: chapter.similarityRatio, containsChapter: String(chapter.containsChapter), endsWithNumber: String(chapter.endsWithNumber)) else {
                fatalError("Error in making isChapter prediction.")
            }
            
            let isChapter = Bool(prediction.isChapter)!
            if isChapter {
                mangoChapters.append(MangoChapter(title: chapter.text, link: chapter.link))
            }
        }
        
        return mangoChapters
    }
    
    static func getPages(pageImageData: [PageImageData]) -> [MangoPage] {
        var mangoPages = [MangoPage]()
        guard let pageClassifier = try? MangoPageClassifier_V2(configuration: MLModelConfiguration()) else {
            fatalError("Error in creating MangoPageClassifier.")
        }
        
        for page in pageImageData {
            guard let prediction = try? pageClassifier.prediction(similarityRatio: page.similarityRatio, isRelatedLink: String(page.isRelatedLink), containsHost: String(page.containsHost), isJPG: String(page.isJPG), hasNumericName: String(page.hasNumericName)) else {
                fatalError("Error in making isPageImage prediction.")
            }
            
            let isPageImage = Bool(prediction.isPageImage)!
            if isPageImage {
                mangoPages.append(MangoPage(imgSrcUrl: page.link))
            }
        }
        
        return mangoPages
    }
    
}
