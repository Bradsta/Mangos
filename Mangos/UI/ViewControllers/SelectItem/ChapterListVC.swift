//
//  ChapterListVC.swift
//  Mangos
//
//  Created by Brad Guerrero on 12/5/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import UIKit
import WebKit

class ChapterListVC : UIViewController {
    
    @IBOutlet weak var chapterTableView: UITableView!
    
    var selectedMango:Mango = Mango()
    static let chapterTableCellReuseId = "ChapterTableCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chapterTableView.delegate = self
        chapterTableView.dataSource = self
        
        self.navigationItem.title = selectedMango.title
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ChapterReadVC {
            let selectedRow = chapterTableView.indexPathForSelectedRow!.row
            let vc = segue.destination as? ChapterReadVC
            vc?.selectedMango = selectedMango
            vc?.selectedChapterIndex = selectedRow
        }
    }
}

extension ChapterListVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedMango.chapterList.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chapterCell = tableView.dequeueReusableCell(withIdentifier: ChapterListVC.chapterTableCellReuseId, for: indexPath) as! ChapterTableCell
        chapterCell.titleLabel.text = selectedMango.chapterList[indexPath.row].title

        return chapterCell
    }
}
