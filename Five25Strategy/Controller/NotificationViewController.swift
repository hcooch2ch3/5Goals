//
//  NotificationViewController.swift
//  Five25Strategy
//
//  Created by 임성민 on 2022/05/05.
//  Copyright © 2022 SeongMin. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController {
    
    @IBOutlet weak var notificationTableView: UITableView!
    var cellCount = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEverydayNotificationOn = UserDefaults.standard.bool(forKey: "EverydayNotification")
        cellCount = isEverydayNotificationOn ? 2 : 1
    }
    
}

extension NotificationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let notificationToggleCell = self.notificationTableView.dequeueReusableCell(withIdentifier: "NotificationToggleCell", for: indexPath) as? NotificationToggleCell else {
                return UITableViewCell()
            }
            
            notificationToggleCell.title?.text = NSLocalizedString("EverydayNotification", comment: "")
            
            notificationToggleCell.toggleSwitch.addTarget(self, action: #selector(toggleSwitch), for: .valueChanged)
            let isEverydayNotificationOn = UserDefaults.standard.bool(forKey: "EverydayNotification")
            notificationToggleCell.toggleSwitch.isOn = isEverydayNotificationOn
            
            return notificationToggleCell
        case 1:
            guard let notificationTimePickerCell = self.notificationTableView.dequeueReusableCell(withIdentifier: "NotificationTimePickerCell", for: indexPath) as? NotificationTimePickerCell else {
                return UITableViewCell()
            }
            return notificationTimePickerCell
        default:
            return UITableViewCell()
        }
    }
    
    @objc func toggleSwitch(sender: UISwitch) {
        if sender.isOn {
            cellCount = 2
            notificationTableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
        } else {
            cellCount = 1
            notificationTableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
        }
        UserDefaults.standard.set(sender.isOn, forKey: "EverydayNotification")
    }
    
}

extension NotificationViewController {
    
    @IBAction func touchUpExitBarButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
