//
//  WishViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/11.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class WishViewController: UIViewController {

    @IBOutlet weak var wishTableView: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var wishes:[Wish]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchWish), name: Notification.Name("FetchWish"), object: nil)

        fetchWish()
    }

    @IBAction func touchUpAddWishButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add Wish", message: "Enter your wish you think seriously.", preferredStyle: .alert)
        alert.addTextField()
        
        /// To do: Exception handling for null string input
        let submitButton = UIAlertAction(title: "Add", style: .default, handler: { (action) in
            let textField = alert.textFields![0]
            
            let newWish = Wish(context: self.context)
            newWish.name = textField.text
            
            do {
                try self.context.save()
            }
            catch {
                
            }
            
            /// To do: Change fetchWish to inserttableview for smooth adding animation
            self.fetchWish()
            
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(submitButton)
        alert.addAction(cancelButton)
        
        self.present(alert, animated: true, completion: nil)
    }

}

extension WishViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.wishes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = wishTableView.dequeueReusableCell(withIdentifier: "WishCell", for: indexPath)
        
        let wish = self.wishes![indexPath.row]
        
        cell.textLabel?.text = wish.name
        
        return cell
    }
    
}

extension WishViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let goalSwipeAction = UIContextualAction(style: .destructive, title: "Goal") { (action, view, completion) in
            // Move wish to goal
            let wishToGoal = self.wishes![indexPath.row]
            let goalFromWish = Goal(context: self.context)
            goalFromWish.name = wishToGoal.name
            self.context.delete(wishToGoal)
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
            
            // Post Notification for fetching goal table view
            NotificationCenter.default.post(name: Notification.Name("FetchGoal"), object: nil)
            
            // Delete wish in wish table view
            self.wishes?.remove(at: indexPath.row)
            self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        
        goalSwipeAction.backgroundColor = UIColor.systemGreen
        
        return UISwipeActionsConfiguration(actions: [goalSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let givingupSwipeAction = UIContextualAction(style: .destructive, title: "Giving-up") { (action, view, completion) in
            // Move wish to giving-up
            let wishToGivingup = self.wishes![indexPath.row]
            let givingupFromWish = Givingup(context: self.context)
            givingupFromWish.name = wishToGivingup.name
            self.context.delete(wishToGivingup)
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
            
            // Post Notification for fetching givingup table view
            NotificationCenter.default.post(name: Notification.Name("FetchGivingup"), object: nil)
            
            // Delete wish in wish table view
            self.wishes?.remove(at: indexPath.row)
            self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        
        givingupSwipeAction.backgroundColor = UIColor.systemRed
        
        return UISwipeActionsConfiguration(actions: [givingupSwipeAction])
    }
    
}

extension WishViewController {
    
    @objc func fetchWish() {
        do {
            self.wishes = try self.context.fetch(Wish.fetchRequest())
            
            DispatchQueue.main.async {
                self.wishTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
}
