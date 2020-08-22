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
    @IBOutlet weak var helpBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var deleteBarButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGivingup"), object: nil)
        
        self.givingupTableView.allowsSelection = false
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
        /// Enable edit button only when there is givingup.
        self.editBarButton.isEnabled = Givingups.shared.givingups.count > 0 ? true : false
        
        /// Update tab bar badge because wish count is changed.
        self.refreshBadge()
        
        return Givingups.shared.givingups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        let givingup = Givingups.shared.givingups[indexPath.row]
        
        cell.textLabel?.text = givingup.name
        
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

extension GivingupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
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
        
        /// Reset priority because of reordering priority
        Givingups.shared.resetPriority()
        
        do {
            try self.context.save()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            let givingupToWish = Givingups.shared.givingups[indexPath.row]
            
            let wishFromGivingup = Wish(context: self.context)
            wishFromGivingup.name = givingupToWish.name
            wishFromGivingup.priority = Int16(Wishes.shared.wishes.count)
             
            self.context.delete(givingupToWish)
            
            /// Reset all wish priority because one of them disappear
            Givingups.shared.resetPriority()
            
            do {
                try self.context.save()
                
                Wishes.shared.wishes.append(wishFromGivingup)
                 
                 NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
                
                Givingups.shared.givingups.remove(at: indexPath.row)
                
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
    
    func refreshBadge() {
        tabBarController?.tabBar.items?[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        tabBarController?.tabBar.items?[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        tabBarController?.tabBar.items?[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
    }
    
    /// This function enable or disable all tab bar items
    func toggleTabbars() {
        tabBarController?.tabBar.items?.forEach {
            $0.isEnabled.toggle()
        }
    }
    
    func toggleEditMode() {
        self.givingupTableView.isEditing.toggle()
        self.helpBarButton.isEnabled.toggle()
        
        /// To enable all tab bar items in normal mode and disable all tab bar items in edit mode
        self.toggleTabbars()
        
        if self.givingupTableView.isEditing {
            self.editBarButton.tintColor = UIColor.systemOrange
            self.deleteBarButton.isEnabled = true
        } else {
            self.editBarButton.tintColor = nil
            self.deleteBarButton.isEnabled = false
        }
    }
    
    func presentWarningAlert(_ message:String) {
         let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
         
         let cancelButton = UIAlertAction(title: "OK", style: .cancel, handler: nil)
         
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
        let alert = UIAlertController(title: "Rename Giving-up", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
            textField.delegate = self
            textField.text = givingup.name
        }
         
        let submitButton = UIAlertAction(title: "Rename", style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            guard textField.text != "" else {
                self.presentWarningAlert("")
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
         
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
         
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
            presentWarningAlert("Check the giving-up to delete.")
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
            
            /// To delete selected wish in data source
            selectedRows.forEach { Givingups.shared.givingups.remove(at: $0.row) }
            
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
       toggleEditMode()
    }
    
    @IBAction func touchUpDeleteBarButton(_ sender:UIBarButtonItem) {
        deleteGivingups()
    }
}
