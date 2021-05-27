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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGivingup"), object: nil)
        
        self.givingupTableView.allowsMultipleSelectionDuringEditing = true
        
        /// For dynamic cell height by text lines
        self.givingupTableView.rowHeight = UITableView.automaticDimension
        self.givingupTableView.estimatedRowHeight = 120
        
        /// To remove empty cell in table view
        self.givingupTableView.tableFooterView = UIView()
        
        self.reload()
    }

}

extension GivingupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// Update tab bar badge because wish count is changed.
        if let tabBarController = tabBarController as? TabBarController {
            tabBarController.refreshTabBarItemsBadge()
        }
        
        return Givingups.shared.givingups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        let givingup = Givingups.shared.givingups[indexPath.row]
        
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
        let movedGivingup = Givingups.shared.givingups[sourceIndexPath.row]
        Givingups.shared.givingups.remove(at: sourceIndexPath.row)
        Givingups.shared.givingups.insert(movedGivingup, at: destinationIndexPath.row)
        
        /// Reset priority because of reordering priority
        Givingups.shared.resetPriority()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Wish", comment: "")) { (action, view, completion) in
            let givingupToWish = Givingups.shared.givingups[indexPath.row]
            
            let wishFromGivingup = Wish(context: self.context)
            wishFromGivingup.name = givingupToWish.name
            wishFromGivingup.priority = Int16(Wishes.shared.wishes.count)
             
            self.context.delete(givingupToWish)
            
            do {
                try self.context.save()
                
                Wishes.shared.wishes.append(wishFromGivingup)
                 
                 NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
                
                Givingups.shared.givingups.remove(at: indexPath.row)
                
                /// Reset all wish priority because one of them disappear
                Givingups.shared.resetPriority()
                
                self.givingupTableView.beginUpdates()
                self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.givingupTableView.endUpdates()
            }
            catch {
                /// To do:
            }
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
}

extension GivingupViewController: UITextFieldDelegate {
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.givingupTableView.reloadData()
        }
    }
    
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
        let givingup = Givingups.shared.givingups[indexPath.row]
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
    
            do {
                try self.context.save()
                
                self.givingupTableView.beginUpdates()
                self.givingupTableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.givingupTableView.endUpdates()
                
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
    
    func deleteGivingups() {
        guard let selectedRows = self.givingupTableView.indexPathsForSelectedRows else {
            presentNoticeAlert(NSLocalizedString("CheckGivingup", comment: "Check the giving-ups to delete."))
            return
        }
        
        var givingupsToRemove: [Givingup] = []
        
        selectedRows.forEach {
            let givingupToRemove = Givingups.shared.givingups[$0.row]
            givingupsToRemove.append(givingupToRemove)
        }
        
        /// To delete givingups in Core Data
        givingupsToRemove.forEach { self.context.delete($0) }
        
        do {
            try self.context.save()
            
            /// To delete selected items in table view data source
            givingupsToRemove.forEach {
                if let index = Givingups.shared.givingups.firstIndex(of: $0) {
                    Givingups.shared.givingups.remove(at: index)
                }
            }
            
            /// To delete table view cell of selected giving-up
            self.givingupTableView.beginUpdates()
            self.givingupTableView.deleteRows(at: selectedRows, with: UITableView.RowAnimation.automatic)
            self.givingupTableView.endUpdates()
            
            /// To exit edit mode after deleting the wishes
            self.toggleEditMode()
        }
        catch {
            
        }
    }
    
}

extension GivingupViewController {
    
    @IBAction func touchUpEditBarButton(_ sender: UIBarButtonItem) {
        guard Givingups.shared.givingups.count > 0 else {
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
