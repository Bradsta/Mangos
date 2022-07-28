//
//  MangosMLData.swift
//  Mangos
//
//  Created by Brad Guerrero on 1/10/21.
//

import Foundation

class MangosMLData {
    private static let minSimilarity = 0.8
    private static let minHrefLength = 2
    private static let httpHostRegex = "http.*://.*?/"
    private static let metadataRegex = "\\?.*"
    
    static func getChapterListHrefData(chapterListUrl: URL, htmlString: String, predict: Bool = false) -> [ChapterHrefData] {
        var hrefDataArray = [ChapterHrefData]()
        var similarityDict = Dictionary<String, Int>()
        
        let chapterListDir = Utility.getUrlLastSection(urlString: chapterListUrl.absoluteString)
        let hrefData = Utility.getHrefData(htmlString: htmlString)
        for href in hrefData {
            let chapterHrefData = ChapterHrefData(link: href.link, text: href.text)
            
            if chapterHrefData.link.count < minHrefLength {
                continue
            }
            
            chapterHrefData.compareLink = chapterHrefData.link.lowercased().replacingOccurrences(of: httpHostRegex, with: "", options: [.regularExpression])
            
            // Ignore duplicates
            let hasHref = hrefDataArray.contains { (existingHrefData) -> Bool in
                return chapterHrefData.link == existingHrefData.link
            }
            if hasHref {
                continue
            }
            
            chapterHrefData.isChildLink = chapterHrefData.link.contains(chapterListDir)
            chapterHrefData.containsChapter = chapterHrefData.link.lowercased().contains("chapter") || chapterHrefData.text.contains("chapter")
            chapterHrefData.endsWithNumber = chapterHrefData.link.range(of: ".*\\d", options: .regularExpression) != nil
            
            var foundSimilarity = false
            for similarityEntry in similarityDict {
                if similarityEntry.key.distance(between: chapterHrefData.compareLink) >= minSimilarity {
                    similarityDict[similarityEntry.key]? += 1
                    foundSimilarity = true
                }
            }
            
            // Add new entry if we couldn't find existing similar links.
            if !foundSimilarity {
                similarityDict[chapterHrefData.compareLink] = 1
            }
            
            hrefDataArray.append(chapterHrefData)
        }
        
        for chapterHrefData in hrefDataArray {
            var highestSimilarityCount = 0
            for similarityEntry in similarityDict {
                if similarityEntry.key.distance(between: chapterHrefData.compareLink) >= minSimilarity && highestSimilarityCount < similarityEntry.value {
                    highestSimilarityCount = similarityEntry.value
                }
            }
            
            chapterHrefData.similarityRatio = Double(highestSimilarityCount) / Double(hrefDataArray.count)
            
            if predict {
                // Decent estimator but should be adjusted depending on what we're logging.
                chapterHrefData.isChapter = chapterHrefData.similarityRatio > 0.5 && chapterHrefData.endsWithNumber
            }
        }
        
        return hrefDataArray
    }
    
    static func getChapterPageImgData(chapterUrl: URL, htmlString: String, predict: Bool = false) -> [PageImageData] {
        var pageImageDataArray = [PageImageData]()
        var similarityDict = Dictionary<String, Int>()
        
        let chapterUrlString = chapterUrl.absoluteString
        let chapterDir = Utility.getUrlLastSection(urlString: chapterUrlString)
        // The prevDir typically contains the name of the manga itself
        var prevDir = chapterUrlString.replacingOccurrences(of: chapterDir, with: "")
        prevDir = Utility.getUrlLastSection(urlString: prevDir)
        
        let imgData = Utility.getImgData(htmlString: htmlString)
        for img in imgData {
            let pageImageData = PageImageData(link: img.link)
            
            if pageImageData.link.count < minHrefLength {
                continue
            }
            
            // Ignore duplicates
            let hasImg = pageImageDataArray.contains { (existingImgData) -> Bool in
                return pageImageData.link == existingImgData.link
            }
            if hasImg {
                continue
            }
            
            pageImageData.compareLink = pageImageData.link.lowercased().replacingOccurrences(of: httpHostRegex, with: "", options: [.regularExpression])
            // Some image links have metadata (e.g., image.jpg?metadata) strip that out.
            pageImageData.compareLink = pageImageData.compareLink.lowercased().replacingOccurrences(of: metadataRegex, with: "", options: [.regularExpression])
            
            // Check if the potential page url contains the chapter directory.
            if !chapterDir.isEmpty {
                pageImageData.isRelatedLink = pageImageData.link.contains(chapterDir)
            }
            
            // Check if the potential page url contains the directory before the chapter directory.
            if !prevDir.isEmpty && !pageImageData.isRelatedLink {
                pageImageData.isRelatedLink = pageImageData.isRelatedLink || pageImageData.link.contains(prevDir)
            }
            
            var foundSimilarity = false
            let pathExtension = (pageImageData.compareLink as NSString).pathExtension
            for similarityEntry in similarityDict {
                // Ensure the similar link has the same path extension on top of being just similar.
                let similarityEntryPathExtension = (similarityEntry.key as NSString).pathExtension
                if pathExtension == similarityEntryPathExtension && similarityEntry.key.distance(between: pageImageData.compareLink) >= minSimilarity {
                    similarityDict[similarityEntry.key]? += 1
                    foundSimilarity = true
                }
            }
            
            // Add new entry if we couldn't find existing similar links.
            if !foundSimilarity {
                similarityDict[pageImageData.compareLink] = 1
            }
            
            pageImageData.containsHost = pageImageData.link.contains(chapterUrl.host!)
            pageImageData.isJPG = pageImageData.link.contains(".jpg") || pageImageData.link.contains(".jpeg")
            
            pageImageData.hasNumericName = true
            let imageFileName = (Utility.getUrlLastSection(urlString: pageImageData.compareLink) as NSString).deletingPathExtension.replacingOccurrences(of: "/", with: "")
            for fileNameChar in imageFileName {
                // Ignore certain characters
                if fileNameChar == "_" || fileNameChar == "-" {
                    continue
                }
                
                // Checking hex digit will allow us to flag hashes as a numeric name.
                if !fileNameChar.isHexDigit {
                    pageImageData.hasNumericName = false
                    break
                }
            }
            
            pageImageDataArray.append(pageImageData)
        }
        
        for pageImageData in pageImageDataArray {
            var highestSimilarityCount = 0
            for similarityEntry in similarityDict {
                if similarityEntry.key.distance(between: pageImageData.compareLink) >= minSimilarity && highestSimilarityCount < similarityEntry.value {
                    highestSimilarityCount = similarityEntry.value
                }
            }
            
            pageImageData.similarityRatio = Double(highestSimilarityCount) / Double(pageImageDataArray.count)
            
            if predict {
                // Decent estimator but should be adjusted depending on what we're logging.
                pageImageData.isPageImage = pageImageData.similarityRatio > 0.5 && pageImageData.isJPG
            }
        }
        
        return pageImageDataArray
    }
    
    static func printChapterHrefData(chapterHrefData: [ChapterHrefData]) {
        print("isChapter, link, compareLink, text, isChildLink, similarityRatio, containsChapter, endsWithNumber")
        for data in chapterHrefData {
            var hrefDataLog = String()
            hrefDataLog.append(String(data.isChapter) + ",")
            hrefDataLog.append(data.link + ",")
            hrefDataLog.append(data.compareLink + ",")
            hrefDataLog.append(data.text + ",")
            hrefDataLog.append(String(data.isChildLink) + ",")
            hrefDataLog.append(String(data.similarityRatio) + ",")
            hrefDataLog.append(String(data.containsChapter) + ",")
            hrefDataLog.append(String(data.endsWithNumber))
            print(hrefDataLog)
        }
    }
    
    static func printPageImageData(pageImageData: [PageImageData]) {
        print("isPageImage, link, compareLink, similarityRatio, isRelatedLink, containsHost, isJPG, hasNumericName")
        for data in pageImageData {
            var imgDataLog = String()
            imgDataLog.append(String(data.isPageImage) + ",")
            imgDataLog.append(data.link + ",")
            imgDataLog.append(data.compareLink + ",")
            imgDataLog.append(String(data.similarityRatio) + ",")
            imgDataLog.append(String(data.isRelatedLink) + ",")
            imgDataLog.append(String(data.containsHost) + ",")
            imgDataLog.append(String(data.isJPG) + ",")
            imgDataLog.append(String(data.hasNumericName))
            print(imgDataLog)
        }
    }

}
