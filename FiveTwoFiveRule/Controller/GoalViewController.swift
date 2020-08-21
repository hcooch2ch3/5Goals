//
//  ViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/11.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class GoalViewController: UIViewController {
    
    @IBOutlet weak var goalTableView: UITableView!
    @IBOutlet weak var helpBarButton: UIBarButtonItem!
    @IBOutlet weak var reorderBarButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGoal"), object: nil)
        
        self.fetchData()
        self.refreshBadge()
        
        /// To remove empty cell in table view
        self.goalTableView.tableFooterView = UIView()
        
        self.goalTableView.reloadData()
    }
        
}

extension GoalViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Goals.shared.goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = goalTableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath)
        
        let goal = Goals.shared.goals[indexPath.row]
        
        cell.textLabel?.text = goal.name
        
        return cell
    }

}

extension GoalViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGoal = Goals.shared.goals[sourceIndexPath.row]
        Goals.shared.goals.remove(at: sourceIndexPath.row)
        Goals.shared.goals.insert(movedGoal, at: destinationIndexPath.row)
        Goals.shared.resetPriority()
        
        self.refreshBadge()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            // Move goal to wish (Add wish and Delete goal)
            let goalToWish = Goals.shared.goals[indexPath.row]
            
            let wishFromGoal = Wish(context: self.context) /// Add wish
            wishFromGoal.name = goalToWish.name
            wishFromGoal.priority = Int16(Wishes.shared.wishes.count)
            Wishes.shared.wishes.append(wishFromGoal)
            
            NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
            
            self.context.delete(goalToWish) /// Delete goal
            Goals.shared.goals.remove(at: indexPath.row)
            self.goalTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            Goals.shared.resetPriority()
            
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

}

extension GoalViewController {
    
    func fetchData() {
        do {
            Goals.shared.goals = try self.context.fetch(Goal.fetchRequest())
            Goals.shared.goals.sort { $0.priority < $1.priority }
            
            Wishes.shared.wishes = try self.context.fetch(Wish.fetchRequest())
            Wishes.shared.wishes.sort { $0.priority < $1.priority }
            
            Givingups.shared.givingups = try self.context.fetch(Givingup.fetchRequest())
            Givingups.shared.givingups.sort { $0.priority < $1.priority }
        }
        catch {
            
        }
    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.goalTableView.reloadData()
        }
    }
    
    func refreshBadge() {
        tabBarController?.tabBar.items?[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        tabBarController?.tabBar.items?[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        tabBarController?.tabBar.items?[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
    }
    
    func toggleTabbars() {
        tabBarController?.tabBar.items?.forEach {
            $0.isEnabled.toggle()
        }
    }
    
    func presentWarningAlert(_ message:String) {
         let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
         
         let cancelButton = UIAlertAction(title: "OK", style: .cancel, handler: nil)
         
         alert.addAction(cancelButton)
         
         self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK:- IBAction
extension GoalViewController {
    
    @IBAction func touchUpReorderBarButton(_ sender: UIBarButtonItem) {
        guard Goals.shared.goals.count > 1 else {
            presentWarningAlert("Reordering is possible when goals are more than 1.")
            return
        }
        
        self.goalTableView.isEditing.toggle()
        self.helpBarButton.isEnabled.toggle()
        self.toggleTabbars()
        
        if self.goalTableView.isEditing {
            sender.tintColor = UIColor.systemPink
        } else {
            sender.tintColor = nil
        }
    }
    
}
