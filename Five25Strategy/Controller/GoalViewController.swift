//
//  ViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/11.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData
import WidgetKit

class GoalViewController: UIViewController {
    
    @IBOutlet weak var goalTableView: UITableView!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGoal"), object: nil)
        
        /// Show help on first use
        if UserDefaults.standard.bool(forKey: "Use") == false {
            performSegue(withIdentifier: "More", sender: nil)
        }
        
        self.goalTableView.allowsMultipleSelectionDuringEditing = true
        
        /// For dynamic cell height by text lines
        self.goalTableView.rowHeight = UITableView.automaticDimension
        self.goalTableView.estimatedRowHeight = 120
        
        /// To remove empty cell in table view
        self.goalTableView.tableFooterView = UIView()
        
        self.fetchData()
        
        /// Move wish tab when there is any goal.
        if Goals.shared.goals.count == 0,
           let tabBarController = tabBarController as? TabBarController {
            tabBarController.moveTab(to: 1)
        }
    
        self.reload()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "More" {
            /// Only execute when showing help first.
            guard UserDefaults.standard.bool(forKey: "Use") == false else {
                return
            }
            
            guard let navigationVC = segue.destination as? UINavigationController, let moreVC = navigationVC.viewControllers[0] as? MoreViewController else {
                return
            }
            
            moreVC.performSegue(withIdentifier: "Help", sender: nil)
        }
    }
            
}

extension GoalViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// Update tab bar badge because goal count is changed.
        if let tabBarController = tabBarController as? TabBarController {
            tabBarController.refreshTabBarItemsBadge()
        }
        
        return Goals.shared.goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = goalTableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath)
        
        let goal = Goals.shared.goals[indexPath.row]
        
        cell.textLabel?.text = "\(goal.priority + 1). \(goal.name!)"
        
        /// For dynamic cell height about text line number
        cell.textLabel?.numberOfLines = 0
        
        /// Add rename button to right side of each cell.
        let RenameButton = UIButton(frame: CGRect(x: tableView.frame.width - 100, y: 0 , width: 40, height: 40))
        RenameButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        RenameButton.tag = indexPath.row
        RenameButton.addTarget(self, action: #selector(touchUpRenameButton(_:_:)), for: .touchUpInside)
        cell.editingAccessoryView = RenameButton
        
        return cell
    }

}

extension GoalViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGoal = Goals.shared.goals[sourceIndexPath.row]
        Goals.shared.goals.remove(at: sourceIndexPath.row)
        Goals.shared.goals.insert(movedGoal, at: destinationIndexPath.row)
        
        /// Reset priority because of reordering priority
        Goals.shared.resetPriority()
        
        if let tabBarController = tabBarController as? TabBarController {
            tabBarController.refreshTabBarItemsBadge()
        }
        
        do {
            try self.context.save()
            
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
            }
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Wish", comment: "")) { (action, view, completion) in
            /// A goal to move the wish area
            let goalToWish = Goals.shared.goals[indexPath.row]
            
            /// New wish from the goal area
            let wishFromGoal = Wish(context: self.context)
            wishFromGoal.name = goalToWish.name
            wishFromGoal.priority = Int16(Wishes.shared.wishes.count)
            
            self.context.delete(goalToWish)
            
            do {
                try self.context.save()
                
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
                }
                
                Wishes.shared.wishes.append(wishFromGoal)
                
                NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
                
                /// Set indexpaths to reload priority.
                var indexPaths: [IndexPath] = []
                for i in 0..<Goals.shared.goals.count {
                    if i == indexPath.row { continue }
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                
                Goals.shared.goals.remove(at: indexPath.row)
                
                /// Reset all wish priority because one of them disappear
                Goals.shared.resetPriority()
                
                self.goalTableView.beginUpdates()
                self.goalTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.goalTableView.reloadRows(at: indexPaths, with: UITableView.RowAnimation.automatic)
                self.goalTableView.endUpdates()
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
        Goals.shared.fetch()
        Wishes.shared.fetch()
        Givingups.shared.fetch()
    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.goalTableView.reloadData()
        }
    }
    
    func toggleEditMode() {
        self.isEditMode.toggle()
        
        if self.isEditMode {
            /// To exit cell swipe status
            if self.goalTableView.isEditing {
                self.goalTableView.setEditing(false, animated: true)
            }
            
            self.goalTableView.setEditing(true, animated: true)
            
            self.editBarButton.image = UIImage(systemName: "escape")
            self.editBarButton.tintColor = UIColor.systemPink
            
            self.leftBarButton.image = UIImage(systemName: "trash.circle")
            
            /// To disable all tab bar items in edit mode
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: false)
            }
        } else {
            self.goalTableView.reloadData()
            
            self.goalTableView.setEditing(false, animated: true)
            
            self.editBarButton.image = UIImage(systemName: "pencil.tip.crop.circle")
            self.editBarButton.tintColor = nil
            
            self.leftBarButton.image = UIImage(systemName: "ellipsis.circle")
            
            /// To enable all tab bar items in normal mode.
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: true)
            }
        }
    }
    
    func presentNoticeAlert(_ message:String) {
         let alert = UIAlertController(title: NSLocalizedString("Notice", comment: ""), message: message, preferredStyle: .alert)
         
         let cancelButton = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
         
         alert.addAction(cancelButton)
         
         self.present(alert, animated: true, completion: nil)
    }
    
    func deleteGoals() {
        guard let selectedRows = self.goalTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckGoal", comment: "Check the goals to delete."))
            return
        }
        
        var goalsToRemove: [Goal] = []
        
        selectedRows.forEach {
            let goalToRemove = Goals.shared.goals[$0.row]
            goalsToRemove.append(goalToRemove)
        }
        
        /// To delete wishes in Core Data
        goalsToRemove.forEach { self.context.delete($0) }
        
        do {
            try self.context.save()
            
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
            }
            
            /// To delete selected items in table view data source
            goalsToRemove.forEach {
                if let index = Goals.shared.goals.firstIndex(of: $0) {
                    Goals.shared.goals.remove(at: index)
                }
            }
            
            /// To delete table view cell of selected goal
            self.goalTableView.beginUpdates()
            self.goalTableView.deleteRows(at: selectedRows, with: UITableView.RowAnimation.automatic)
            self.goalTableView.endUpdates()
            
            /// To exit edit mode after deleting the goals
            self.toggleEditMode()
        }
        catch {
            
        }
    }
    
}

extension GoalViewController: UITextFieldDelegate {
    
    @objc func touchUpRenameButton(_ sender: UIButton, _ event: UIEvent) {
        /// To find cell's index path whose edit button is touched
        let touch = event.allTouches?.first as AnyObject
        let point = touch.location(in: self.goalTableView)
        guard let indexPath = self.goalTableView.indexPathForRow(at: point) else { return }
        
        self.presentRenameGoalAlert(indexPath)
    }
    
    func presentRenameGoalAlert(_ indexPath: IndexPath) {
        let goal = Goals.shared.goals[indexPath.row]
        let alert = UIAlertController(title: NSLocalizedString("RenameGoal", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = goal.name
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            guard textField.text != "" else {
                return
            }
        
            goal.name = textField.text
    
            do {
                try self.context.save()
                
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
                }
                
                self.goalTableView.beginUpdates()
                self.goalTableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.goalTableView.endUpdates()
                
                /// To exit edit mode after renaming wish.
                self.toggleEditMode()
            }
            catch {
             
            }
        })
         
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
         
        alert.addAction(submitButton)
        alert.addAction(cancelButton)
        alert.actions[0].isEnabled = false // Add Button's default value is false
         
        self.present(alert, animated: true, completion: nil)
    }
    
    /// This function is to detect whether alert's text field is blank string or not.
    /// This function to enable alert's OK button when text field is not blank string.
    @objc func textChanged(_ sender: Any) {
        let textfield = sender as! UITextField
        
        /// To find the alert controller whose textfield is changed
        var responder : UIResponder? = textfield
        while !(responder is UIAlertController) { responder = responder?.next }
        let alert = responder as? UIAlertController
        
        alert?.actions[0].isEnabled = (textfield.text != "")
    }
    
}

// MARK:- IBAction
extension GoalViewController {
    
    @IBAction func touchUpEditBarButton(_ sender: UIBarButtonItem) {
        guard Goals.shared.goals.count > 0 else {
            presentNoticeAlert(NSLocalizedString("EditGoalUnavailable", comment: ""))
            return
        }
        
        toggleEditMode()
    }
    
    @IBAction func touchUpLeftBarButton(_ sender: UIBarButtonItem) {
        if self.isEditMode {
            deleteGoals()
        } else {
            performSegue(withIdentifier: "More", sender: sender)
        }
    }
    
}
