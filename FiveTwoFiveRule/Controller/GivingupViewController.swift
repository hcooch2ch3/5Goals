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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("ReloadGivingup"), object: nil)
        
        fetchGivingup()
    }

}

extension GivingupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Givingups.shared.givingups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = givingupTableView.dequeueReusableCell(withIdentifier: "GivingupCell", for: indexPath)
        
        let givingup = Givingups.shared.givingups[indexPath.row]
        
        cell.textLabel?.text = givingup.name
        
        return cell
    }
    
}

extension GivingupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wishSwipeAction = UIContextualAction(style: .destructive, title: "Wish") { (action, view, completion) in
            // Move givingup to wish
            let givingupToWish = Givingups.shared.givingups[indexPath.row]
            
            let wishFromGivingup = Wish(context: self.context)
            wishFromGivingup.name = givingupToWish.name
            
            self.context.delete(givingupToWish)
            
            do {
                try self.context.save()
                
                Wishes.shared.wishes.append(wishFromGivingup)
                NotificationCenter.default.post(name: Notification.Name("ReloadWish"), object: nil)
                
                Givingups.shared.givingups.remove(at: indexPath.row)
                self.givingupTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            }
            catch {
                /// To do:
            }
        }
        
        wishSwipeAction.backgroundColor = UIColor.systemYellow
        
        return UISwipeActionsConfiguration(actions: [wishSwipeAction])
    }
    
}

extension GivingupViewController {
    
    func fetchGivingup() {
        do {
            Givingups.shared.givingups = try self.context.fetch(Givingup.fetchRequest())
            
            DispatchQueue.main.async {
                self.givingupTableView.reloadData()
            }
        }
        catch {
            
        }
    }
    
    @objc func reload() {
        DispatchQueue.main.async {
            self.givingupTableView.reloadData()
        }
    }
    
}
