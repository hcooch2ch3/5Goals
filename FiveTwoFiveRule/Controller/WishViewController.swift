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
        
        fetchWish()
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
            
            self.context.delete(wishToGoal)
            
            do {
                try self.context.save()
            
                Goals.shared.goals.append(goalFromWish)
                NotificationCenter.default.post(name: Notification.Name("ReloadGoal"), object: nil)
                
                Wishes.shared.wishes.remove(at: indexPath.row)
                self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
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
            
            self.context.delete(wishToGivingup)
            
            do {
                try self.context.save()
                
                Givingups.shared.givingups.append(givingupFromWish)
                NotificationCenter.default.post(name: Notification.Name("ReloadGivingup"), object: nil)
                
                Wishes.shared.wishes.remove(at: indexPath.row)
                self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
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
    
    @IBAction func touchUpAddWishButton(_ sender: UIBarButtonItem) {
        guard (Goals.shared.goals.count + Wishes.shared.wishes.count + Givingups.shared.givingups.count) < 25 else {
            // To do: Show Alert
            return
        }
        
        presentAddWishAlert()
    }
    
}

extension WishViewController {
    
    func fetchWish() {
        do {
            Wishes.shared.wishes = try self.context.fetch(Wish.fetchRequest())
            
            DispatchQueue.main.async {
                self.wishTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
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
             
             do {
                 try self.context.save()
                 
                 Wishes.shared.wishes.append(wish)
                 
                 // Insert Wish Cell
                 self.wishTableView.beginUpdates()
                 self.wishTableView.insertRows(at: [IndexPath(row: Wishes.shared.wishes.count - 1, section: 0)], with: UITableView.RowAnimation.none)
                 self.wishTableView.endUpdates()
             }
             catch {
                 
             }
         })
         
         let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
         
         alert.addAction(submitButton)
         alert.addAction(cancelButton)
         
         self.present(alert, animated: true, completion: nil)
    }
    
}
