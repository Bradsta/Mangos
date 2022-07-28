//
//  Mango.swift
//  Mangos
//
//  Created by Brad Guerrero on 11/12/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import SwiftUI
import StringMetric
import SwiftSoup

class MangoChapter : NSObject, NSCoding {
    var title = String()
    var link = String()
    
    init(title: String, link: String = String()) {
        self.title = title
        self.link = link
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(title, forKey: "title")
        coder.encode(link, forKey: "link")
    }
    
    required convenience init?(coder: NSCoder) {
        guard let title = coder.decodeObject(forKey: "title") as? String,
              let link = coder.decodeObject(forKey: "link") as? String
        else { return nil }

        self.init(
            title: title,
            link: link
        )
    }
}

class Mango : NSObject, NSCoding {
    var title = String()
    var chapterList = [MangoChapter]()
    var host = String()
    
    init(title: String = String(), chapterList: [MangoChapter] = [MangoChapter](), host: String = String()) {
        self.title = title
        self.chapterList = chapterList
        self.host = host
    }
    
    func getCatalogueTitle() -> String {
        return title + " (" + String(chapterList.count) + ")"
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(title, forKey: "title")
        coder.encode(chapterList, forKey: "chapterList")
        coder.encode(host, forKey: "host")
    }
    
    required convenience init?(coder: NSCoder) {
        guard let title = coder.decodeObject(forKey: "title") as? String,
              let chapterList = coder.decodeObject(forKey: "chapterList") as? [MangoChapter],
              let host = coder.decodeObject(forKey: "host") as? String
        else { return nil }

        self.init(
            title: title,
            chapterList: chapterList,
            host: host
        )
    }
}
