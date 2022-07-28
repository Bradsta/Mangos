//
//  Utility.swift
//  Mangos
//
//  Created by Brad Guerrero on 11/18/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import Foundation
import UIKit
import SwiftSoup

class Utility {
    private static let imgSrcString = "src=\""
    
    static func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    static func parseImgSource(in text: String) -> String {
        var imgSrc = String()
        let srcSplit = text.components(separatedBy: Utility.imgSrcString)
        if srcSplit.count > 1 {
            let srcContents = srcSplit[1]
            let srcEnd = srcContents.firstIndex(of: "\"")
            if srcEnd != nil {
                imgSrc = String(srcContents[..<srcEnd!])
            }
        }
        return imgSrc
    }
    
    static func base64ToImage(base64: String) -> UIImage? {
        var img: UIImage = UIImage()
        if (!base64.isEmpty) {
            if let decodedData = NSData(base64Encoded: base64 , options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                if let decodedimage = UIImage(data: decodedData as Data) {
                    img = (decodedimage as UIImage?)!
                    return img
                }
            }
        }
        return nil
    }
    
    static func getHrefData(htmlString: String) -> [HrefData] {
        var hrefData = [HrefData]()
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let hrefs: Elements = try doc.select("[href]")
            for href in hrefs {
                let hrefText: String = try href.text()
                var hrefLink: String = try href.attr("href")
                hrefLink = Utility.trimUrl(urlString: hrefLink)
                
                hrefData.append(HrefData(link: hrefLink, text: hrefText))
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("Unknown error in getHrefData.")
        }
        return hrefData
    }
    
    static func getImgData(htmlString: String) -> [ImgData] {
        var imgData = [ImgData]()
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let imgs: Elements = try doc.select("img")
            for img in imgs {
                var imgLink: String = try img.attr("src")
                if imgLink.isEmpty {
                    imgLink = try img.attr("data-src")
                    // Properly extract url if needed.
                    imgLink = getUrl(text: imgLink)
                }
                
                imgLink = Utility.trimUrl(urlString: imgLink)
                imgData.append(ImgData(link: imgLink))
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("Unknown error in getImgData.")
        }
        return imgData
    }
    
    static func getUrlLastSection(urlString: String) -> String {
        var urlString = urlString
        var lastSection = String()
        
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        
        let urlLastSectionIndex = urlString.lastIndex(of: "/")
        if urlLastSectionIndex != nil {
            lastSection = String(urlString[urlLastSectionIndex!...])
        }
        
        return lastSection
    }
    
    static func trimUrl(urlString: String) -> String {
        var urlString = urlString
        
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        
        return urlString
    }
    
    static func handleIncomingURL(_ url: URL) -> Bool{
        if let scheme = url.scheme,
            scheme.caseInsensitiveCompare("mangos") == .orderedSame {
            let mangoUrl = url.absoluteString.replacingOccurrences(of: "mangos://", with: "")
            UserDefaults().set(mangoUrl, forKey: "incomingURL")
            return true
        }
        return false
    }
    
    static func getUrl(text: String) -> String {
        let types: NSTextCheckingResult.CheckingType = .link
        
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
            let urls = matches.compactMap({$0.url})
            if urls.count > 0 {
                return urls[0].absoluteString
            }
        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return text
    }
}

// Credits: https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift
extension StringProtocol {
    
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    
    // Credits: https://stackoverflow.com/questions/31746223/number-of-occurrences-of-substring-in-string-in-swift
    func count(of needle: Character) -> Int {
        return reduce(0) {
            $1 == needle ? $0 + 1 : $0
        }
    }
    
    func replaceLast(character: Character) -> String {
        var result = String(self)
        if !result.isEmpty && result.last! == character {
            result = String(result.dropLast())
        }
        return result
    }
}
