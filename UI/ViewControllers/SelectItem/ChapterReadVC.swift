//
//  ChapterReadVC.swift
//  Mangos
//
//  Created by Brad Guerrero on 12/7/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import UIKit
import WebKit

class ChapterReadVC : UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var mangoWebView = WKWebView()
    
    var selectedMango = Mango()
    var selectedChapterIndex = 0
    var pageNumberIndex = 0
    
    private var mangoPages = [MangoPage]()
    private var currentUrlStr = String()
    private var chapterHref = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mangoWebView.navigationDelegate = self
        
        if selectedChapterIndex < selectedMango.chapterList.count {
            chapterHref = selectedMango.chapterList[selectedChapterIndex].link
            currentUrlStr = chapterHref.contains(selectedMango.host) ? chapterHref : selectedMango.host + chapterHref
            print("Chapter url: " + currentUrlStr)
            let chapterUrl = URL(string: currentUrlStr)
            let chapterUrlRequest = URLRequest(url: chapterUrl!)
            mangoWebView.load(chapterUrlRequest)
            showLoadingPage()
        }
        
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: nil,
                                               queue: .main,
                                               using: didRotate)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
    }
    
    func loadMangoPage(pageIndex: Int, continueLoading: Bool) {
        if pageIndex >= 0 && pageIndex < mangoPages.count {
            let url = URL(string: self.mangoPages[pageIndex].imgSrcUrl)
            if url == nil {
                print("Image url invalid: " + self.mangoPages[pageIndex].imgSrcUrl)
                if continueLoading {
                    self.loadMangoPage(pageIndex: pageIndex + 1, continueLoading: continueLoading)
                }
                return
            }
            print("Loading page " + String(pageIndex) + ": " + url!.absoluteString)
            
            URLSession.shared.dataTask(with: url!) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                    else { return }
                DispatchQueue.main.async() {
                    self.mangoPages[pageIndex].uiImage = image
                    self.mangoPages[pageIndex].isLoaded = true
                    self.collectionView.reloadItems(at: [IndexPath(item: pageIndex, section: 0)])
                    
                    if continueLoading {
                        self.loadMangoPage(pageIndex: pageIndex + 1, continueLoading: continueLoading)
                    }
                }
            }.resume()
        }
    }
    
    func showLoadingPage() {
        // Show loading spinner on dummy mango page
        let loadingPage = MangoPage()
        loadingPage.isLoaded = false
        mangoPages.append(loadingPage)
        collectionView.reloadData()
    }
    
    var didRotate: (Notification) -> Void = { notification in
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            print("landscape")
        case .portrait, .portraitUpsideDown:
            print("Portrait")
        default:
            print("other")
        }
    }
}

extension ChapterReadVC : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
           completionHandler: {
            (html: Any?, error: Error?) in
            let htmlString:String = html as? String ?? ""
            
            if !htmlString.isEmpty {
                let pageImageData = MangosMLData.getChapterPageImgData(chapterUrl: self.mangoWebView.url!, htmlString: htmlString)
                let pages = MangosML.getPages(pageImageData: pageImageData)
                if pages.count > 0 {
                    print("Found " + String(pages.count) + " pages.")
                    self.mangoPages = pages
                    self.collectionView.reloadData()
                    self.loadMangoPage(pageIndex: 0, continueLoading: true)
                } else {
                    print("Unable to find pages.")
                }
            }
        })
    }
    
}

extension ChapterReadVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mangoPages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pageCell = collectionView.dequeueReusableCell(withReuseIdentifier: MangoPageViewCell.mangoPageViewCellReuseId, for: indexPath) as! MangoPageViewCell
        
        pageCell.imageScrollView.setup()
        pageCell.imageScrollView.frame = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: collectionView.frame.height)
        
        let mangoPage = self.mangoPages[indexPath.item]
        if mangoPage.isLoaded {
            pageCell.imageScrollView.display(image: mangoPage.uiImage)
            pageCell.activityIndicator.stopAnimating()
        }

        return pageCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }
    
}
