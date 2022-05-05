//
//  MoreViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/27.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit

class MoreViewController: UIViewController {
    
    @IBOutlet weak var moreTableView: UITableView!
    
    let contents: [(name: String, imageName: String, segueIdentifier: String)] = [(NSLocalizedString("Help", comment: ""), "questionmark", "Help"), (NSLocalizedString("Notification", comment: ""), "bell.badge", "Notification")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.moreTableView.rowHeight = 80
        
        self.moreTableView.reloadData()
    }
    
}

extension MoreViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.moreTableView.dequeueReusableCell(withIdentifier: "MoreCell", for: indexPath)
        
        let content = self.contents[indexPath.row]
        
        cell.textLabel?.text = content.name
        cell.imageView?.image = UIImage(systemName: content.imageName)
        
        return cell
    }

}

extension MoreViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segueIdentifier = self.contents[indexPath.row].segueIdentifier
        performSegue(withIdentifier: segueIdentifier, sender: nil)
        self.moreTableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension MoreViewController {
    
    @IBAction func touchUpExitBarButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
