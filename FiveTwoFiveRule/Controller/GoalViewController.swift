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
    var goals: [Goal]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchGoal), name: Notification.Name("FetchGoal"), object: nil)
        
        fetchGoal()
    }
    
    @objc func fetchGoal() {
        do {
            self.goals = try self.context.fetch(Goal.fetchRequest())
            
            DispatchQueue.main.async {
                self.goalTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
}

extension GoalViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.goals?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = goalTableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath)
        
        let goal = self.goals![indexPath.row]
        
        cell.textLabel?.text = goal.name
        
        return cell
    }

}

extension GoalViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            // Move goal to wish
            let goalToWish = self.goals![indexPath.row]
            let wishFromGoal = Wish(context: self.context)
            wishFromGoal.name = goalToWish.name
            self.context.delete(goalToWish)
            do {
                try self.context.save()
            }
            catch {
                /// To do:
            }
            
            // Post Notification for fetching givingup table view
            NotificationCenter.default.post(name: Notification.Name("FetchWish"), object: nil)
            
            // Delete wish in wish table view
            self.goals?.remove(at: indexPath.row)
            self.goalTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
}
