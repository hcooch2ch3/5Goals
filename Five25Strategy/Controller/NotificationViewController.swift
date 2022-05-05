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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension NotificationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let notificationToggleCell = self.notificationTableView.dequeueReusableCell(withIdentifier: "NotificationToggleCell", for: indexPath) as? NotificationToggleCell else {
                return UITableViewCell()
            }
            notificationToggleCell.title?.text = "Everyday Notification"
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
    
}

extension NotificationViewController {
    
    @IBAction func touchUpExitBarButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
