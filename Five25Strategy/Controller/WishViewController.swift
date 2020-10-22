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
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadWish"), object: nil)
        
        self.wishTableView.allowsMultipleSelectionDuringEditing = true
        
        /// For dynamic cell height by text lines
        self.wishTableView.rowHeight = UITableView.automaticDimension
        self.wishTableView.estimatedRowHeight = 120
        
        /// To remove empty cell in table view
        self.wishTableView.tableFooterView = UIView()
        
        self.reload()
    }
    
}

extension WishViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// Update tab bar badge because wish count is changed.
        self.refreshBadge()
        
        return Wishes.shared.wishes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = wishTableView.dequeueReusableCell(withIdentifier: "WishCell", for: indexPath)
        
        let wish = Wishes.shared.wishes[indexPath.row]
        
        cell.textLabel?.text = wish.name
        
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

extension WishViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedWish = Wishes.shared.wishes[sourceIndexPath.row]
        Wishes.shared.wishes.remove(at: sourceIndexPath.row)
        Wishes.shared.wishes.insert(movedWish, at: destinationIndexPath.row)
        
        /// Reset priority because of reordering priority
        Wishes.shared.resetPriority()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let goalSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Goal", comment: "")) { (action, view, completion) in
            guard Goals.shared.goals.count < 5 else {
                self.presentNoticeAlert("The number of goals cannot exceed 5.")
                return
            }
            
            /// A wish to move goal area
            let wishToGoal = Wishes.shared.wishes[indexPath.row]
            
            /// New goal from the wish area
            let goalFromWish = Goal(context: self.context)
            goalFromWish.name = wishToGoal.name
            goalFromWish.priority = Int16(Goals.shared.goals.count)
            
            self.context.delete(wishToGoal)
            
            /// Reset all wish priority because one of them disappear
            Wishes.shared.resetPriority()

            do {
                try self.context.save()
                
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
                }
                
                Goals.shared.goals.append(goalFromWish)
                
                NotificationCenter.default.post(name: Notification.Name("ReloadGoal"), object: nil)
                
                Wishes.shared.wishes.remove(at: indexPath.row)
                
                self.wishTableView.beginUpdates()
                self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.wishTableView.endUpdates()
            }
            catch {
                
            }
        }
        
        goalSwipeAction.backgroundColor = UIColor.systemGreen
        
        return UISwipeActionsConfiguration(actions: [goalSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let givingupSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Giving-up", comment: "")) { (action, view, completion) in
            /// A wish to move the giving-up area
            let wishToGivingup = Wishes.shared.wishes[indexPath.row]
            
            /// New giving-up from the wish area
            let givingupFromWish = Givingup(context: self.context)
            givingupFromWish.name = wishToGivingup.name
            givingupFromWish.priority = Int16(Givingups.shared.givingups.count)
            
            self.context.delete(wishToGivingup)
            
            /// Reset all wish priority because one of them disappear
            Wishes.shared.resetPriority()
            
            do {
                try self.context.save()
                
                Givingups.shared.givingups.append(givingupFromWish)
                
                NotificationCenter.default.post(name: Notification.Name("ReloadGivingup"), object: nil)
                
                Wishes.shared.wishes.remove(at: indexPath.row)
                
                self.wishTableView.beginUpdates()
                self.wishTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.wishTableView.endUpdates()
            }
            catch {

            }
        }
        
        givingupSwipeAction.backgroundColor = UIColor.systemRed
        
        return UISwipeActionsConfiguration(actions: [givingupSwipeAction])
    }
    
}

extension WishViewController: UITextFieldDelegate {
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.wishTableView.reloadData()
        }
    }
    
    func refreshBadge() {
        tabBarController?.tabBar.items?[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        tabBarController?.tabBar.items?[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        tabBarController?.tabBar.items?[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
    }
    
    /// This function enable or disable all tab bar items
    func setTabbarEnabled(_ able: Bool) {
        tabBarController?.tabBar.items?.forEach {
            $0.isEnabled = able
        }
    }
    
    func toggleEditMode() {
        self.isEditMode.toggle()
        
        if self.isEditMode {
            /// To exit cell swipe status
            if self.wishTableView.isEditing {
                self.wishTableView.setEditing(false, animated: true)
            }
            
            self.wishTableView.setEditing(true, animated: true)
            
            self.addBarButton.isEnabled = false
            
            self.editBarButton.image = UIImage(systemName: "xmark.square")
            self.editBarButton.tintColor = UIColor.systemPink
            
            self.leftBarButton.image = UIImage(systemName: "trash")
            
            /// To disable all tab bar items in edit mode
            self.setTabbarEnabled(false)
        } else {
            self.wishTableView.setEditing(false, animated: true)
            
            self.addBarButton.isEnabled = true
            
            self.editBarButton.image = UIImage(systemName: "square.and.pencil")
            self.editBarButton.tintColor = nil
            
            self.leftBarButton.image = UIImage(systemName: "ellipsis")
            
            /// To enable all tab bar items in normal mode.
            self.setTabbarEnabled(true)
        }
    }
    
    func presentAddWishAlert() {
        let alert = UIAlertController(title: NSLocalizedString("AddWish", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { texfield in
            texfield.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            texfield.delegate = self
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            guard textField.text != "" else {
                self.presentNoticeAlert("")
                return
            }
             
            let wish = Wish(context: self.context)
            wish.name = textField.text
            wish.priority = Int16(Wishes.shared.wishes.count)

            do {
                try self.context.save()
                
                Wishes.shared.wishes.append(wish)

                /// Insert Wish Cell.
                let indexPath = IndexPath(row: Wishes.shared.wishes.count - 1, section: 0)
                self.wishTableView.beginUpdates()
                self.wishTableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.none)
                self.wishTableView.endUpdates()
                
                /// Show inserted cell.
                self.wishTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    
    func presentRenameWishAlert(_ indexPath: IndexPath) {
        let wish = Wishes.shared.wishes[indexPath.row]
        let alert = UIAlertController(title: NSLocalizedString("RenameWish", comment: ""), message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = wish.name
        }
         
        let submitButton = UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            guard textField.text != "" else {
                return
            }
        
            wish.name = textField.text
    
            do {
                try self.context.save()
                
                self.wishTableView.beginUpdates()
                self.wishTableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.wishTableView.endUpdates()
                
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
    
    func deleteWishes() {
        guard let selectedRows = self.wishTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckWish", comment: "Check the wishes to delete."))
            return
        }
        
        var wishesToRemove: [Wish] = []
        
        selectedRows.forEach {
            let wishToRemove = Wishes.shared.wishes[$0.row]
            wishesToRemove.append(wishToRemove)
        }
        
        /// To delete wishes in Core Data
        wishesToRemove.forEach { self.context.delete($0) }
        
        do {
            try self.context.save()
            
            /// To delete selected items in table view data source
            wishesToRemove.forEach {
                if let index = Wishes.shared.wishes.firstIndex(of: $0) {
                    Wishes.shared.wishes.remove(at: index)
                }
            }
            
            /// To delete table view cell of selected wish
            self.wishTableView.beginUpdates()
            self.wishTableView.deleteRows(at: selectedRows, with: UITableView.RowAnimation.automatic)
            self.wishTableView.endUpdates()
            
            /// To exit edit mode after deleting the wishes
            self.toggleEditMode()
        }
        catch {
            
        }
    }
    
}

// MARK:- IBAction
extension WishViewController {
    
    @IBAction func touchUpAddWishBarButton(_ sender: UIBarButtonItem) {
        guard (Goals.shared.goals.count + Wishes.shared.wishes.count + Givingups.shared.givingups.count) < 25 else {
            presentNoticeAlert(NSLocalizedString("TotalNumberExceed", comment: "The total number cannot exceed 25."))
            return
        }
        
        presentAddWishAlert()
    }
    
    @IBAction func touchUpEditBarButton(_ sender:UIBarButtonItem) {
        guard Wishes.shared.wishes.count > 0 else {
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
