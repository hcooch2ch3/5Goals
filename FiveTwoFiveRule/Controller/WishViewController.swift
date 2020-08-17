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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadWish"), object: nil)
        
        self.reload()
    }
    
}

extension WishViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Wishes.shared.wishes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = wishTableView.dequeueReusableCell(withIdentifier: "WishCell", for: indexPath)
        
        let wish = Wishes.shared.wishes[indexPath.row]
        
        cell.textLabel?.text = wish.name
        
        return cell
    }
    
}

extension WishViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedWish = Wishes.shared.wishes[sourceIndexPath.row]
        Wishes.shared.wishes.remove(at: sourceIndexPath.row)
        Wishes.shared.wishes.insert(movedWish, at: destinationIndexPath.row)
        Wishes.shared.resetPriority()
        
        self.refreshBadge()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let goalSwipeAction = UIContextualAction(style: .destructive, title: "Goal") { (action, view, completion) in
            guard Goals.shared.goals.count < 5 else {
                // To do: Show Alert
                return
            }
            
            // Move wish to goal
            let wishToGoal = Wishes.shared.wishes[indexPath.row]
            
            let goalFromWish = Goal(context: self.context)
            goalFromWish.name = wishToGoal.name
            goalFromWish.priority = Int16(Goals.shared.goals.count)
            Goals.shared.goals.append(goalFromWish)
            
            NotificationCenter.default.post(name: Notification.Name("ReloadGoal"), object: nil)
            
            self.context.delete(wishToGoal)
            Wishes.shared.wishes.remove(at: indexPath.row)
            self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            Wishes.shared.resetPriority()
            
            self.refreshBadge()
            
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
        }
        
        goalSwipeAction.backgroundColor = UIColor.systemGreen
        
        return UISwipeActionsConfiguration(actions: [goalSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let givingupSwipeAction = UIContextualAction(style: .destructive, title: "Giving-up") { (action, view, completion) in
            // Move wish to giving-up
            let wishToGivingup = Wishes.shared.wishes[indexPath.row]
            
            let givingupFromWish = Givingup(context: self.context)
            givingupFromWish.name = wishToGivingup.name
            givingupFromWish.priority = Int16(Givingups.shared.givingups.count)
            Givingups.shared.givingups.append(givingupFromWish)
            
            NotificationCenter.default.post(name: Notification.Name("ReloadGivingup"), object: nil)
            
            self.context.delete(wishToGivingup)
            Wishes.shared.wishes.remove(at: indexPath.row)
            self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            Wishes.shared.resetPriority()
            
            self.refreshBadge()
            
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
        }
        
        givingupSwipeAction.backgroundColor = UIColor.systemRed
        
        return UISwipeActionsConfiguration(actions: [givingupSwipeAction])
    }
    
}

extension WishViewController {
    
//    func fetchWish() {
//        do {
//            Wishes.shared.wishes = try self.context.fetch(Wish.fetchRequest())
//            Wishes.shared.wishes.sort { $0.priority < $1.priority }
//
//            self.refreshBadge()
//
//            DispatchQueue.main.async {
//                self.wishTableView.reloadData()
//            }
//        }
//        catch {
//
//        }
//    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.wishTableView.reloadData()
        }
    }
    
    func presentAddWishAlert() {
         let alert = UIAlertController(title: "Add Wish", message: "Enter your wish you think seriously.", preferredStyle: .alert)
         alert.addTextField()
         
         /// To do: Exception handling for null string input
         let submitButton = UIAlertAction(title: "Add", style: .default, handler: { (action) in
             let textField = alert.textFields![0]
             
             let wish = Wish(context: self.context)
             wish.name = textField.text
            wish.priority = Int16(Wishes.shared.wishes.count)
            Wishes.shared.wishes.append(wish)
            
            // Insert Wish Cell
            self.wishTableView.beginUpdates()
            self.wishTableView.insertRows(at: [IndexPath(row: Wishes.shared.wishes.count - 1, section: 0)], with: UITableView.RowAnimation.none)
            self.wishTableView.endUpdates()
            
            self.refreshBadge()
            
             do {
                 try self.context.save()
             }
             catch {
                 
             }
         })
         
         let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
         
         alert.addAction(submitButton)
         alert.addAction(cancelButton)
         
         self.present(alert, animated: true, completion: nil)
    }
    
    func refreshBadge() {
        tabBarController?.tabBar.items?[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        tabBarController?.tabBar.items?[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        tabBarController?.tabBar.items?[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
    }
    
}

// MARK:- IBAction
extension WishViewController {
    
    @IBAction func touchUpAddWishButton(_ sender: UIBarButtonItem) {
        guard (Goals.shared.goals.count + Wishes.shared.wishes.count + Givingups.shared.givingups.count) < 25 else {
            // To do: Show Alert
            return
        }
        
        presentAddWishAlert()
    }
    
    @IBAction func touchUpEditButton(_ sender:UIBarButtonItem) {
        self.wishTableView.isEditing.toggle()
    }
    
}
