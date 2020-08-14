//
//  GivingupViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/11.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class GivingupViewController: UIViewController {

    @IBOutlet weak var givingupTableView: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var givingups:[Givingup]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchGivingup), name: Notification.Name("FetchGivingup"), object: nil)
        
        fetchGivingup()
    }

}

extension GivingupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.givingups?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        let givingup = self.givingups![indexPath.row]
        
        cell.textLabel?.text = givingup.name
        
        return cell
    }
    
    
}

extension GivingupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            // Move givingup to wish
            let givingupToWish = self.givingups![indexPath.row]
            let wishFromGivingup = Wish(context: self.context)
            wishFromGivingup.name = givingupToWish.name
            self.context.delete(givingupToWish)
            do {
                try self.context.save()
            } catch {
                /// To do:
            }
            
            // Post Notification for fetching wish table view
            NotificationCenter.default.post(name: Notification.Name("FetchWish"), object: nil)
            
            // Delete givingup in givingup table view
            self.givingups?.remove(at: indexPath.row)
            self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteSwipeAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            // Delete givingup
            
            let givingupToDelete = self.givingups![indexPath.row]
            
            self.context.delete(givingupToDelete)
            do {
                try self.context.save()
            }
            catch {
                
            }
            
            // Delete givingup in givingup table view
            self.givingups?.remove(at: indexPath.row)
            self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        
        deleteSwipeAction.backgroundColor = UIColor.systemGray
        
        return UISwipeActionsConfiguration(actions: [deleteSwipeAction])
    }
    
}

extension GivingupViewController {
    
    @objc func fetchGivingup() {
        do {
            self.givingups = try self.context.fetch(Givingup.fetchRequest())
            
            DispatchQueue.main.async {
                self.givingupTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
}
