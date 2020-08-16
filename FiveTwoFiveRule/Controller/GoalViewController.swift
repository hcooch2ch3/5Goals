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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGoal"), object: nil)
        
        fetchGoal()
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
        if self.goalTableView.isEditing {
            return UITableViewCell.EditingStyle.delete
        }
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let goalToDelete = Goals.shared.goals[indexPath.row]
            self.context.delete(goalToDelete)
            
            Goals.shared.goals.remove(at: indexPath.row)
            self.goalTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            Goals.shared.resetPriority()
            
            do {
                try self.context.save()
            }
            catch {
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGoal = Goals.shared.goals[sourceIndexPath.row]
        Goals.shared.goals.remove(at: sourceIndexPath.row)
        Goals.shared.goals.insert(movedGoal, at: destinationIndexPath.row)
        Goals.shared.resetPriority()
        
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
    
    func fetchGoal() {
        do {
            Goals.shared.goals = try self.context.fetch(Goal.fetchRequest())
            Goals.shared.goals.sort { $0.priority < $1.priority }
            
            DispatchQueue.main.async {
                self.goalTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.goalTableView.reloadData()
        }
    }
    
}

// MARK:- IBAction
extension GoalViewController {
    
    @IBAction func touchUpEditButton(_ sender: UIBarButtonItem) {
        self.goalTableView.isEditing.toggle()
    }
    
}
