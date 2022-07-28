//
//  TestDataVC.swift
//  Mangos
//
//  Created by Brad Guerrero on 10/27/21.
//  Copyright © 2021 Brad Guerrero. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class TestDataVC : UIViewController {
    
    private var mangoWebView = WKWebView()
    
    private static var testChapterLinks = [
        "https://mangahere.onl/manga/return-of-immortal-emperor",
        "https://mangapanda.onl/manga/coffee-vanilla",
        "https://kissmanga.org/manga/dz919342",
        "https://bato.to/series/80296/flirting-with-the-villain-s-dad",
        "https://www.mangaread.org/manga/cultivator-against-hero-society/",
        "https://mangareader.site/manga/fairy-tail-100-years-quest_103"
    ]
    
    private static var testChapterPagesLinks = [
        "https://mangahere.onl/chapter/return-of-immortal-emperor/chapter-154",
        "https://mangapanda.onl/chapter/coffee-vanilla/chapter-16",
        "https://kissmanga.org/chapter/dz919342/chapter_52",
        "https://bato.to/chapter/1544051",
        "https://www.mangaread.org/manga/cultivator-against-hero-society/chapter-50/",
        "https://mangareader.site/chapter/fairy-tail-100-years-quest_103/chapter-72",
        "https://mangaeffect.com/manga/isekai-shokudou/chapter-23/"
    ]
    
    var isPrintingChapterLinks = false
    var isPrintingPageLinks = false
    var linkIndex = -1
    
    override func viewDidLoad() {
        mangoWebView.navigationDelegate = self
    }
    
    func isPrintingActive() -> Bool {
        return isPrintingPageLinks || isPrintingChapterLinks
    }
    
    func loadNextLink(linkList: [String]) {
        linkIndex += 1
        
        if linkIndex >= 0 && linkIndex < linkList.count {
            print("~ SEPARATOR ~")
            let url = URL(string: linkList[linkIndex])
            let urlRequest = URLRequest(url: url!)
            mangoWebView.load(urlRequest)
        } else {
            isPrintingPageLinks = false
            isPrintingChapterLinks = false
            linkIndex = -1
        }
    }
    
    @IBAction func onPrintChapterTestData(_ sender: Any) {
        if isPrintingActive() {
            return
        }
        
        isPrintingChapterLinks = true
        loadNextLink(linkList: TestDataVC.testChapterLinks)
    }
    
    @IBAction func onPrintPageTestData(_ sender: Any) {
        if isPrintingActive() {
            return
        }
        
        isPrintingPageLinks = true
        loadNextLink(linkList: TestDataVC.testChapterPagesLinks)
    }
    
}

extension TestDataVC : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
           completionHandler: {
            (html: Any?, error: Error?) in
            if !self.isPrintingActive() {
                return
            }
            
            let htmlString:String = html as? String ?? ""
            if self.isPrintingChapterLinks {
                let chapterHrefData = MangosMLData.getChapterListHrefData(chapterListUrl: self.mangoWebView.url!, htmlString: htmlString, predict: true)
                MangosMLData.printChapterHrefData(chapterHrefData: chapterHrefData)
                self.loadNextLink(linkList: TestDataVC.testChapterLinks)
            } else if self.isPrintingPageLinks {
                let pageImageData = MangosMLData.getChapterPageImgData(chapterUrl: self.mangoWebView.url!, htmlString: htmlString, predict: true)
                MangosMLData.printPageImageData(pageImageData: pageImageData)
                self.loadNextLink(linkList: TestDataVC.testChapterPagesLinks)
            }
        })
    }
    
}
