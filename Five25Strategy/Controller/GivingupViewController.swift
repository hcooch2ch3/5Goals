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
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    private var isEditMode = false
    private var minDeletedRow: Int? = nil
    private lazy var fetchedResultsController = FetchedResultsController(context: PersistentContainer.shared.viewContext, key: #keyPath(Givingup.priority), delegate: self, Givingup.self)
    private var isSwipeDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: 예외처리 추가.
            print("Fail to fetch givingup data.")
        }
        
        self.givingupTableView.allowsMultipleSelectionDuringEditing = true
        
        /// For dynamic cell height by text lines
        self.givingupTableView.rowHeight = UITableView.automaticDimension
        self.givingupTableView.estimatedRowHeight = 120
        
        /// To remove empty cell in table view
        self.givingupTableView.tableFooterView = UIView()
    }
    
}

extension GivingupViewController: UITableViewDataSource {
    
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
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        guard let givingup = fetchedResultsController.object(at: indexPath) as? Givingup else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = givingup.name
        
        /// For dynamic cell height about text line number
        cell.textLabel?.numberOfLines = 0
        
        /// Add rename button to right side of each cell.
        let renameButton = UIButton(frame: CGRect(x: tableView.frame.width - 100, y: 0 , width: 40, height: 40))
        renameButton.setImage(UIImage(systemName: "pencil.tip.crop.circle"), for: .normal)
        renameButton.tag = indexPath.row
        renameButton.addTarget(self, action: #selector(touchUpRenameButton(_:_:)), for: .touchUpInside)
        cell.editingAccessoryView = renameButton
        
        return cell
    }
    
}

extension GivingupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard var givingups = fetchedResultsController.fetchedObjects as? [Givingup] else {
            return
        }
        let movedGivingup = givingups.remove(at: sourceIndexPath.row)
        givingups.insert(movedGivingup, at: destinationIndexPath.row)
        
        if sourceIndexPath.row < destinationIndexPath.row {
            for index in sourceIndexPath.row...destinationIndexPath.row {
                givingups[index].priority = Int16(index)
            }
        } else {
            for index in destinationIndexPath.row...sourceIndexPath.row {
                givingups[index].priority = Int16(index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Wish", comment: "")) { (action, view, completion) in
            guard let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")) else {
                // TODO: To localize alert string
                return
            }
            
            self.isSwipeDone = true
            
            guard let givingupToWish = self.fetchedResultsController.object(at: indexPath) as? Givingup else {
                return
            }
            
            let wishFromGivingup = Wish(context: PersistentContainer.shared.viewContext)
            wishFromGivingup.name = givingupToWish.name
            wishFromGivingup.priority = Int16(wishCount)
            
            PersistentContainer.shared.viewContext.delete(givingupToWish)
            
            self.minDeletedRow = indexPath.row
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
}

extension GivingupViewController: UITextFieldDelegate {
    
    func toggleEditMode() {
        self.isEditMode.toggle()
        
        if self.isEditMode {
            /// To exit cell swipe status
            if self.givingupTableView.isEditing {
                self.givingupTableView.setEditing(false, animated: true)
            }
            
            self.givingupTableView.setEditing(true, animated: true)
            
            self.editBarButton.image = UIImage(systemName: "escape")
            self.editBarButton.tintColor = UIColor.systemPink
            
            self.leftBarButton.image = UIImage(systemName: "trash.circle")
            
            /// To disable all tab bar items in edit mode
            if let tabBarController = tabBarController as? TabBarController {
                tabBarController.changeTabBarItemsState(to: false)
            }
        } else {
            self.givingupTableView.setEditing(false, animated: true)
            
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
    
    @objc func touchUpRenameButton(_ sender: UIButton, _ event: UIEvent) {
        /// To find cell's index path whose edit button is touched
        let touch = event.allTouches?.first as AnyObject
        let point = touch.location(in: self.givingupTableView)
        guard let indexPath = self.givingupTableView.indexPathForRow(at: point) else { return }
        
        self.presentRenameGivingupAlert(indexPath)
    }
    
    func presentRenameGivingupAlert(_ indexPath: IndexPath) {
        guard let givingup = fetchedResultsController.object(at: indexPath) as? Givingup else {
            return
        }
        let alert = UIAlertController(title: NSLocalizedString("RenameGivingup", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = givingup.name
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            guard textField.text != "" else {
                return
            }
        
            givingup.name = textField.text
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
    
    func deleteGivingups() {
        guard let selectedRows = self.givingupTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckGivingup", comment: "Check the giving-ups to delete."))
            return
        }
        guard let givingups = fetchedResultsController.fetchedObjects as? [Givingup] else {
            return
        }
        
        var minDeletedRow = givingups.count - selectedRows.count - 1
        selectedRows.forEach {
            PersistentContainer.shared.viewContext.delete(givingups[$0.row])
            if $0.row < minDeletedRow {
                minDeletedRow = $0.row
            }
        }
        if minDeletedRow >= 0 {
            self.minDeletedRow = minDeletedRow
        }
        
        self.toggleEditMode()
    }
    
    private func resetPriorityIfDeletionIsDone() {
        if let minDeletedRow = self.minDeletedRow {
            guard let givingups = fetchedResultsController.fetchedObjects as? [Givingup] else {
                return
            }
            
            for row in minDeletedRow..<givingups.count {
                givingups[row].priority = Int16(row)
            }
            self.minDeletedRow = nil
        }
    }
    
}

extension GivingupViewController {
    
    @IBAction func touchUpEditBarButton(_ sender: UIBarButtonItem) {
        guard let section = fetchedResultsController.sections?[0], section.numberOfObjects > 0 else {
            presentNoticeAlert(NSLocalizedString("EditGivingupUnavailable", comment: ""))
            return
        }
        
       toggleEditMode()
    }
    
    @IBAction func touchUpLeftBarButton(_ sender:UIBarButtonItem) {
        if self.isEditMode {
            deleteGivingups()
        } else {
            performSegue(withIdentifier: "More", sender: sender)
        }
    }
    
}

extension GivingupViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        givingupTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let indexPath = indexPath else {
                return
            }
            givingupTableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            guard let newIndexPath = newIndexPath else {
                return
            }
            givingupTableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else {
                return
            }
            givingupTableView.reloadRows(at: [indexPath], with: .automatic)
            guard let newIndexPath = newIndexPath else {
                return
            }
            givingupTableView.reloadRows(at: [newIndexPath], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        givingupTableView.endUpdates()
        resetPriorityIfDeletionIsDone()
        if isSwipeDone == false {
            PersistentContainer.shared.saveContext()
        } else {
            isSwipeDone = false
        }
    }
    
}
