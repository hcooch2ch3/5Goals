//
//  WishViewController.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/11.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData
import WidgetKit

class WishViewController: UIViewController {

    @IBOutlet weak var wishTableView: UITableView!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var topSpaceHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceHeightConstraint: NSLayoutConstraint!
    
    var isScrollToBottom = false
    private var isEditMode = false
    private lazy var fetchedResultsController = FetchedResultsController(context: PersistentContainer.shared.viewContext, key: #keyPath(Wish.priority), delegate: self, Wish.self)
    private var lastUserAction: UserAction = UserAction.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topSpaceHeightConstraint.constant = topSpaceHeight
        bottomSpaceHeightConstraint.constant = bottomSpaceHeight
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: 예외처리 추가.
            print("Fail to fetch wish data.")
        }
        
        self.wishTableView.allowsMultipleSelectionDuringEditing = true
        
        /// For dynamic cell height by text lines
        self.wishTableView.rowHeight = UITableView.automaticDimension
        self.wishTableView.estimatedRowHeight = 120
        
        /// To remove empty cell in table view
        self.wishTableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isScrollToBottom {
            let lastRow = wishTableView.numberOfRows(inSection: 0) - 1
            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: 0)
                wishTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            isScrollToBottom = false
        }
    }
    
}

extension WishViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// Update tab bar badge because wish count is changed.
        if let tabBarController = tabBarController as? TabBarController {
            tabBarController.refreshTabBarItemsBadge()
        }
        
        guard let section = fetchedResultsController.sections?[section] else {
            return 0
        }
        return section.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = wishTableView.dequeueReusableCell(withIdentifier: "WishCell", for: indexPath) as? IdeaCell else {
            return UITableViewCell()
        }
        
        guard let wish = fetchedResultsController.object(at: indexPath) as? Wish else {
            return UITableViewCell()
        }
        
        cell.ideaLabel.text = wish.name
        
        /// Add rename button to right side of each cell.
        let renameButton = UIButton(frame: CGRect(x: tableView.frame.width - 100, y: 0 , width: 40, height: 40))
        renameButton.setImage(UIImage(systemName: "pencil.tip.crop.circle"), for: .normal)
        renameButton.tag = indexPath.row
        renameButton.addTarget(self, action: #selector(touchUpRenameButton(_:_:)), for: .touchUpInside)
        cell.editingAccessoryView = renameButton
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .systemYellow
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
}

extension WishViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath else {
            return
        }
        guard var wishes = fetchedResultsController.fetchedObjects as? [Wish] else {
            return
        }
        let movedWish = wishes.remove(at: sourceIndexPath.row)
        wishes.insert(movedWish, at: destinationIndexPath.row)
        
        if sourceIndexPath.row < destinationIndexPath.row {
            for index in sourceIndexPath.row...destinationIndexPath.row {
                wishes[index].priority = Int16(index)
            }
        } else {
            for index in destinationIndexPath.row...sourceIndexPath.row {
                wishes[index].priority = Int16(index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let goalSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Goal", comment: "")) { [weak self] (action, view, completion) in
            guard let goalCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Goal")), goalCount < 5 else {
                self?.presentNoticeAlert(NSLocalizedString("GoalNumberExceed", comment: ""))
                return
            }
            
            guard let wishToGoal = self?.fetchedResultsController.object(at: indexPath) as? Wish else {
                return
            }
            
            let goalFromWish = Goal(context: PersistentContainer.shared.viewContext)
            goalFromWish.name = wishToGoal.name
            goalFromWish.priority = Int16(goalCount)
            
            PersistentContainer.shared.viewContext.delete(wishToGoal)
            
            self?.lastUserAction = .swipe(indexPath.row)
        }
        
        goalSwipeAction.backgroundColor = UIColor.systemGreen
        
        return UISwipeActionsConfiguration(actions: [goalSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let givingupSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Giving-up", comment: "")) { [weak self] (action, view, completion) in
            guard let givingupCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Givingup")) else {
                return
            }
            
            guard let wishToGivingup = self?.fetchedResultsController.object(at: indexPath) as? Wish else {
                return
            }
            
            let givingupFromWish = Givingup(context: PersistentContainer.shared.viewContext)
            givingupFromWish.name = wishToGivingup.name
            givingupFromWish.priority = Int16(givingupCount)
            
            PersistentContainer.shared.viewContext.delete(wishToGivingup)
            
            self?.lastUserAction = .swipe(indexPath.row)
        }
        
        givingupSwipeAction.backgroundColor = UIColor.systemRed
        
        return UISwipeActionsConfiguration(actions: [givingupSwipeAction])
    }
    
}

extension WishViewController: UITextFieldDelegate {
        
    func toggleEditMode() {
        self.isEditMode.toggle()
        
        if self.isEditMode {
            /// To exit cell swipe status
            if self.wishTableView.isEditing {
                self.wishTableView.setEditing(false, animated: true)
            }
            
            self.wishTableView.setEditing(true, animated: true)
            
            self.addBarButton.isEnabled = false
            
            self.editBarButton.image = UIImage(systemName: "arrow.forward.circle.fill")
            
            self.leftBarButton.image = UIImage(systemName: "trash.circle")
            
            /// To disable all tab bar items in edit mode
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: false)
            }
        } else {
            self.wishTableView.setEditing(false, animated: true)
            
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

        alert.addTextField { [weak self] texfield in
            texfield.addTarget(self, action: #selector(self?.textChanged), for: .editingChanged)
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
    
    func presentRenameWishAlert(_ indexPath: IndexPath) {
        guard let wish = fetchedResultsController.object(at: indexPath) as? Wish else {
            return
        }
        let alert = UIAlertController(title: NSLocalizedString("RenameWish", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { [weak self] textField in
            textField.addTarget(self, action: #selector(self?.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = wish.name
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]
            guard textField.text != "" else {
                return
            }
            wish.name = textField.text
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
    
    @objc func touchUpRenameButton(_ sender: UIButton, _ event: UIEvent) {
        /// To find cell's index path whose edit button is touched
        let touch = event.allTouches?.first as AnyObject
        let point = touch.location(in: self.wishTableView)
        guard let indexPath = self.wishTableView.indexPathForRow(at: point) else { return }
        
        self.presentRenameWishAlert(indexPath)
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
    
    func addWish(_ name: String) {
        guard let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")) else {
            return
        }
        let wish = Wish(context: PersistentContainer.shared.viewContext)
        wish.name = name
        wish.priority = Int16(wishCount)
        self.lastUserAction = .add(wishCount)
    }
    
    func deleteWishes() {
        guard let selectedRows = self.wishTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckWish", comment: "Check the wishes to delete."))
            return
        }
        
        guard let wishes = fetchedResultsController.fetchedObjects as? [Wish] else {
            return
        }
        
        var minDeletedRow = wishes.count - selectedRows.count - 1
        selectedRows.forEach {
            PersistentContainer.shared.viewContext.delete(wishes[$0.row])
            if $0.row < minDeletedRow {
                minDeletedRow = $0.row
            }
        }
        if minDeletedRow >= 0 {
            self.lastUserAction = .delete(minDeletedRow)
        }
        
        self.toggleEditMode()
    }
    
    private func resetPriority(from minDeletedRow: Int) {
        guard let wishes = fetchedResultsController.fetchedObjects as? [Wish] else {
            return
        }
        
        for row in minDeletedRow..<wishes.count {
            wishes[row].priority = Int16(row)
        }
    }
    
}

// MARK:- IBAction
extension WishViewController {
    
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
    
    @IBAction func touchUpEditBarButton(_ sender:UIBarButtonItem) {
        guard let section = fetchedResultsController.sections?[0], section.numberOfObjects > 0 else {
            presentNoticeAlert(NSLocalizedString("EditWishUnavailable", comment: ""))
            return
        }
        
        toggleEditMode()
    }
    
    @IBAction func touchUpLeftBarButton(_ sender:UIBarButtonItem) {
        if self.isEditMode {
            deleteWishes()
        } else {
            performSegue(withIdentifier: "More", sender: sender)
        }
    }
    
}

extension WishViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        wishTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let indexPath = indexPath else {
                return
            }
            wishTableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            guard let newIndexPath = newIndexPath else {
                return
            }
            wishTableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else {
                return
            }
            wishTableView.reloadRows(at: [indexPath], with: .automatic)
            guard let newIndexPath = newIndexPath else {
                return
            }
            wishTableView.reloadRows(at: [newIndexPath], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        wishTableView.endUpdates()
        switch lastUserAction {
        case .add(let row):
            let indexPath = IndexPath(row: row, section: 0)
            self.wishTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        case .delete(let minDeletedRow):
            resetPriority(from: minDeletedRow)
        case .swipe(let minDeletedRow):
            resetPriority(from: minDeletedRow)
            lastUserAction = .none
            return
        default:
            break
        }
        PersistentContainer.shared.saveContext()
        lastUserAction = .none
    }
    
}
