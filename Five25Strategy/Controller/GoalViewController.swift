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
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var topSpaceHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceHeightConstraint: NSLayoutConstraint!
    
    private var isEditMode = false
    private lazy var fetchedResultsController = FetchedResultsController(context: PersistentContainer.shared.viewContext, key: #keyPath(Goal.priority), delegate: self, Goal.self)
    private var lastUserAction: UserAction = UserAction.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topSpaceHeightConstraint.constant = topSpaceHeight
        bottomSpaceHeightConstraint.constant = bottomSpaceHeight
        
        setNavigationBarClear()
        setTabBarClear()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: 예외처리 추가.
            print("Fail to fetch goal data.")
        }
        
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
        
        /// Move wish tab when there is any goal.
        if let section = fetchedResultsController.sections?[0],
           section.numberOfObjects == 0,
           let tabBarController = tabBarController as? TabBarController {
            tabBarController.moveTab(to: 1)
        }
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
        
        guard let section = fetchedResultsController.sections?[section] else {
            return 0
        }
        return section.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = goalTableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath) as? IdeaCell else {
            return UITableViewCell()
        }
        
        guard let goal = fetchedResultsController.object(at: indexPath) as? Goal else {
            return UITableViewCell()
        }
        
        // TODO: To implement cell init method
//        cell.textLabel?.text = "\(goal.priority + 1). \(goal.name!)"
        cell.ideaLabel.text = "\(goal.priority + 1). \(goal.name!)"
        
        /// Add rename button to right side of each cell.
        let renameButton = UIButton(frame: CGRect(x: tableView.frame.width - 100, y: 0 , width: 40, height: 40))
        renameButton.setImage(UIImage(systemName: "pencil.tip.crop.circle"), for: .normal)
        renameButton.tag = indexPath.row
        renameButton.addTarget(self, action: #selector(touchUpRenameButton(_:_:)), for: .touchUpInside)
        cell.editingAccessoryView = renameButton
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .systemGreen
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
    
    
}

extension GoalViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath else {
            return
        }
        guard var goals = fetchedResultsController.fetchedObjects as? [Goal] else {
            return
        }
        let movedGoal = goals.remove(at: sourceIndexPath.row)
        goals.insert(movedGoal, at: destinationIndexPath.row)
        
        if sourceIndexPath.row < destinationIndexPath.row {
            for index in sourceIndexPath.row...destinationIndexPath.row {
                goals[index].priority = Int16(index)
            }
        } else {
            for index in destinationIndexPath.row...sourceIndexPath.row {
                goals[index].priority = Int16(index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Wish", comment: "")) { [weak self] (action, view, completion) in
            guard let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")) else {
                return
            }
            
            guard let goalToWish = self?.fetchedResultsController.object(at: indexPath) as? Goal else {
                return
            }
            
            // New wish from the goal area
            let wishFromGoal = Wish(context: PersistentContainer.shared.viewContext)
            wishFromGoal.name = goalToWish.name
            wishFromGoal.priority = Int16(wishCount)
            
            PersistentContainer.shared.viewContext.delete(goalToWish)
            
            self?.lastUserAction = .swipe(indexPath.row, .wish)
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }

}

extension GoalViewController {
        
    func toggleEditMode() {
        self.isEditMode.toggle()
        
        if self.isEditMode {
            /// To exit cell swipe status
            if self.goalTableView.isEditing {
                self.goalTableView.setEditing(false, animated: true)
            }
            
            self.goalTableView.setEditing(true, animated: true)
            
            self.addBarButton.isEnabled = false
            
            self.editBarButton.image = UIImage(systemName: "arrow.forward.circle.fill")
            
            self.leftBarButton.image = UIImage(systemName: "trash.circle")
            
            /// To disable all tab bar items in edit mode
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: false)
            }
        } else {
            self.goalTableView.setEditing(false, animated: true)
            
            self.addBarButton.isEnabled = true
            
            self.editBarButton.image = UIImage(systemName: "pencil.tip.crop.circle")
            
            self.leftBarButton.image = UIImage(systemName: "ellipsis.circle")
            
            /// To enable all tab bar items in normal mode.
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: true)
            }
        }
    }
    
    func presentAddWishAlert() {
        let alert = UIAlertController(title: NSLocalizedString("AddWish", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { texfield in
            texfield.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            texfield.delegate = self
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default, handler: { [weak self] (action) in
            let textField = alert.textFields![0]
            guard let text = textField.text,
                  text != "" else {
                return
            }
            self?.addWish(text)
        })
         
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
         
        alert.addAction(submitButton)
        alert.addAction(cancelButton)
        alert.actions[0].isEnabled = false // Add Button's default value is false
         
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentNoticeAlert(_ message:String) {
         let alert = UIAlertController(title: NSLocalizedString("Notice", comment: ""), message: message, preferredStyle: .alert)
         
         let cancelButton = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
         
         alert.addAction(cancelButton)
         
         self.present(alert, animated: true, completion: nil)
    }
    
    func addWish(_ name: String) {
        guard let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")) else {
            return
        }
        let wish = Wish(context: PersistentContainer.shared.viewContext)
        wish.name = name
        wish.priority = Int16(wishCount)
        
        guard let tabBarController = self.tabBarController as? TabBarController else {
            return
        }
        
        if tabBarController.isWishViewControllerLoaded == false {
            PersistentContainer.shared.saveContext()
        }
        
        tabBarController.moveTabToWishAndScrollToBottom()
    }
    
    private func deleteGoals() {
        guard var selectedRows = self.goalTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckGoal", comment: "Check the goals to delete."))
            return
        }
        selectedRows.sort {
            $0.row > $1.row
        }
        guard let goals = fetchedResultsController.fetchedObjects as? [Goal] else {
            return
        }
        selectedRows.forEach {
            PersistentContainer.shared.viewContext.delete(goals[$0.row])
        }
        
        if let minDeletedRow = selectedRows.last?.row {
            self.lastUserAction = .delete(minDeletedRow)
        }
        
        self.toggleEditMode()
    }
    
    private func resetPriority(from minDeletedRow: Int) {
        guard let goals = fetchedResultsController.fetchedObjects as? [Goal] else {
            return
        }
        
        for row in minDeletedRow..<goals.count {
            goals[row].priority = Int16(row)
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
        guard let goal = fetchedResultsController.object(at: indexPath) as? Goal else {
            return
        }
        let alert = UIAlertController(title: NSLocalizedString("RenameGoal", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { [weak self] textField in
            textField.addTarget(self, action: #selector(self?.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = goal.name
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]
            guard textField.text != "" else {
                return
            }
            goal.name = textField.text
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
    
    @IBAction func touchUpAddWishBarButton(_ sender: UIBarButtonItem) {
        guard let goalCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Goal")), let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")), let givingupCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Givingup"))
              else {
            return
        }
        guard goalCount + wishCount + givingupCount < 25 else {
            presentNoticeAlert(NSLocalizedString("TotalNumberExceed", comment: "The total number cannot exceed 25."))
            return
        }
        
        presentAddWishAlert()
    }
    
    @IBAction func touchUpEditBarButton(_ sender: UIBarButtonItem) {
        guard let section = fetchedResultsController.sections?[0], section.numberOfObjects > 0 else {
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

extension GoalViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        NotificationViewController.refreshNotifications()
        goalTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let indexPath = indexPath else {
                return
            }
            goalTableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            guard let newIndexPath = newIndexPath else {
                return
            }
            goalTableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else {
                return
            }
            goalTableView.reloadRows(at: [indexPath], with: .automatic)
            guard let newIndexPath = newIndexPath else {
                return
            }
            goalTableView.reloadRows(at: [newIndexPath], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        goalTableView.endUpdates()
        switch lastUserAction {
        case .delete(let minDeletedRow):
            resetPriority(from: minDeletedRow)
        case .swipe(let minDeletedRow, let destination):
            resetPriority(from: minDeletedRow)
            PersistentContainer.shared.saveContext()
            if destination == .wish {
                NotificationViewController.refreshNotifications()
            }
            if let tabBarController = tabBarController as? TabBarController, tabBarController.isWishViewControllerLoaded {
                lastUserAction = .none
                return
            }
        default:
            break
        }
        PersistentContainer.shared.saveContext()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
        }
        lastUserAction = .none
    }
}
