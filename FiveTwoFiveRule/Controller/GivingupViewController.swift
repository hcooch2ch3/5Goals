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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGivingup"), object: nil)
        
        self.reload()
    }

}

extension GivingupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Givingups.shared.givingups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        let givingup = Givingups.shared.givingups[indexPath.row]
        
        cell.textLabel?.text = givingup.name
        
        return cell
    }
    
}

extension GivingupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGivingup = Givingups.shared.givingups[sourceIndexPath.row]
        Givingups.shared.givingups.remove(at: sourceIndexPath.row)
        Givingups.shared.givingups.insert(movedGivingup, at: destinationIndexPath.row)
        Givingups.shared.resetPriority()
        
        self.refreshBadge()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            // Move givingup to wish
            let givingupToWish = Givingups.shared.givingups[indexPath.row]
            
            let wishFromGivingup = Wish(context: self.context)
            wishFromGivingup.name = givingupToWish.name
            wishFromGivingup.priority = Int16(Wishes.shared.wishes.count)
            Wishes.shared.wishes.append(wishFromGivingup)
            
            NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
            
            self.context.delete(givingupToWish)
            Givingups.shared.givingups.remove(at: indexPath.row)
            self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            
            self.refreshBadge()
            
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteSwipeAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            let givingupToDelete = Givingups.shared.givingups[indexPath.row]
            self.context.delete(givingupToDelete)
            
            Givingups.shared.givingups.remove(at: indexPath.row)
            self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            
            Givingups.shared.resetPriority()
            
            self.refreshBadge()
            
            do {
                try self.context.save()
            }
            catch {
                
            }
        }
        
        deleteSwipeAction.backgroundColor =     UIColor.systemGray
        
        return UISwipeActionsConfiguration(actions: [deleteSwipeAction])
    }
    
}

extension GivingupViewController {
    
//    func fetchGivingup() {
//        do {
//            Givingups.shared.givingups = try self.context.fetch(Givingup.fetchRequest())
//            Givingups.shared.givingups.sort { $0.priority < $1.priority }
//
//            self.refreshBadge()
//
//            DispatchQueue.main.async {
//                self.givingupTableView.reloadData()
//            }
//        }
//        catch {
//
//        }
//    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.givingupTableView.reloadData()
        }
    }
    
    func refreshBadge() {
        tabBarController?.tabBar.items?[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        tabBarController?.tabBar.items?[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        tabBarController?.tabBar.items?[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
    }
    
}

extension GivingupViewController {
    
    @IBAction func touchUpEditButton(_ sender: UIBarButtonItem) {
        self.givingupTableView.isEditing.toggle()
    }
}
