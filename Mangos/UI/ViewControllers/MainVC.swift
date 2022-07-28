//
//  ViewController.swift
//  Mangos
//
//  Created by Brad Guerrero on 11/7/19.
//  Copyright © 2019 Brad Guerrero. All rights reserved.
//

import UIKit
import WebKit

class MainVC : UIViewController {

    @IBOutlet weak var mangoTableView: UITableView!
    
    private static let mangoTableCellReuseId = "MangoTableCell"
    private static let mangosFileName = "mangos"
    
    private var mangoWebView = WKWebView()
    private var trackedMango = [Mango]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mangoTableView.delegate = self
        mangoTableView.dataSource = self
        mangoWebView.navigationDelegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidBecomeActiveNotification(notification:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        readMangoFromFile()
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleAppDidBecomeActiveNotification(notification: Notification) {
        if let incomingURL = UserDefaults().value(forKey: "incomingURL") as? String {
            print("Incoming url: " + incomingURL)
            
            // Pop to MainVC if not already on it.
            navigationController?.popToRootViewController(animated: true)
            
            // Source: https://stackoverflow.com/a/56358881
            let alert = UIAlertController(title: "Adding Title", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                self.mangoWebView.stopLoading()
            }))
            
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.isUserInteractionEnabled = false
            activityIndicator.startAnimating()

            alert.view.addSubview(activityIndicator)
            alert.view.heightAnchor.constraint(equalToConstant: 125).isActive = true

            activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor, constant: 0).isActive = true
            activityIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -55).isActive = true

            present(alert, animated: true)
            
            let mangoUrl = URL(string: incomingURL)
            let mangoUrlRequest = URLRequest(url: mangoUrl!)
            mangoWebView.load(mangoUrlRequest)
            
            UserDefaults().removeObject(forKey: "incomingURL")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ChapterListVC {
            let selectedRow = mangoTableView.indexPathForSelectedRow!.row
            let vc = segue.destination as? ChapterListVC
            vc?.selectedMango = trackedMango[selectedRow]
        }
    }
    
    func readMangoFromFile() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(MainVC.mangosFileName)

        do {
            let data = try Data(contentsOf: path)
            if let mangos = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Mango] {
                self.trackedMango = mangos
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func writeMangoToFile() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(MainVC.mangosFileName)

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: trackedMango, requiringSecureCoding: false)
            try data.write(to: path)
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func addMango(mango: Mango) {
        let enterTitleAC = UIAlertController(title: "Enter Title", message: nil, preferredStyle: .alert)
        enterTitleAC.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned enterTitleAC] _ in
            let title = enterTitleAC.textFields![0]
            mango.title = title.text!
            
            self.trackedMango.append(mango)
            self.writeMangoToFile()
            self.mangoTableView.reloadData()
        }
        enterTitleAC.addAction(submitAction)
        present(enterTitleAC, animated: true)
    }

}

extension MainVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackedMango.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mangoCell = tableView.dequeueReusableCell(withIdentifier: MainVC.mangoTableCellReuseId, for: indexPath) as! MangoTableCell
        
        let nextMango = trackedMango[indexPath.row]
        mangoCell.titleLabel.text = nextMango.title + " (" + String(nextMango.chapterList.count) + ")"
        
        return mangoCell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.trackedMango.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.writeMangoToFile()
        }
    }
}

extension MainVC : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
           completionHandler: {
            (html: Any?, error: Error?) in
            let htmlString:String = html as? String ?? ""

            let chapterListUrl = self.mangoWebView.url!
            let chapterHrefData = MangosMLData.getChapterListHrefData(chapterListUrl: chapterListUrl, htmlString: htmlString)
            let chapterList = MangosML.getChapters(chapterHrefData: chapterHrefData)
            
            self.dismiss(animated: false, completion: nil)
            if chapterList.count > 0 {
                let parsedMango = Mango()
                parsedMango.host = "https://" + (chapterListUrl.host ?? "")
                parsedMango.chapterList = chapterList
                self.addMango(mango: parsedMango)
            } else {
                let alert = UIAlertController(title: "Unable to parse mango!", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        })
    }
}
