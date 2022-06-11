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
    var cellCount = 1
    var isEverydayNotificationOn = false {
        didSet {
            cellCount = isEverydayNotificationOn ? 2 : 1
            DispatchQueue.main.async {
                self.notificationTableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) -> Void in
            if settings.authorizationStatus != .authorized {
                UserDefaults.standard.set(false, forKey: "EverydayNotification")
                self.isEverydayNotificationOn = false
            }
        })
        isEverydayNotificationOn = UserDefaults.standard.bool(forKey: "EverydayNotification")
        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification,
            object: nil)
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
            notificationToggleCell.toggleSwitch.isOn = isEverydayNotificationOn
            
            return notificationToggleCell
        case 1:
            guard let notificationTimePickerCell = self.notificationTableView.dequeueReusableCell(withIdentifier: "NotificationTimePickerCell", for: indexPath) as? NotificationTimePickerCell else {
                return UITableViewCell()
            }
            notificationTimePickerCell.timePicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
            
            let hour = UserDefaults.standard.integer(forKey: "EverydayNotificationHour")
            let minute = UserDefaults.standard.integer(forKey: "EverydayNotificationMinute")
            if let presetDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                notificationTimePickerCell.timePicker.setDate(presetDate, animated: true)
            }
            
            return notificationTimePickerCell
        default:
            return UITableViewCell()
        }
    }
    
    @objc func toggleSwitch(sender: UISwitch) {
        if sender.isOn {
            let center = UNUserNotificationCenter.current()

            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if granted {
                    DispatchQueue.main.async {
                        self.cellCount = 2
                        self.notificationTableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
                        UserDefaults.standard.set(sender.isOn, forKey: "EverydayNotification")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlertAboutSettings()
                        sender.isOn = false
                    }
                }
            }
        } else {
            cellCount = 1
            notificationTableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            UserDefaults.standard.set(sender.isOn, forKey: "EverydayNotification")
        }
    }
    
    func showAlertAboutSettings() {
       let defaultAction = UIAlertAction(title: "확인",
                            style: .default) { (action) in
           self.goToSettings()
       }
       let cancelAction = UIAlertAction(title: "취소",
                            style: .cancel)
       
       let alert = UIAlertController(title: "알림",
             message: "설정에서 알림을 허용해야만 목표 알림이 가능합니다.",
             preferredStyle: .alert)
       alert.addAction(defaultAction)
       alert.addAction(cancelAction)
            
       self.present(alert, animated: true)
    }
    
    func goToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc func timeChanged(_ sender: UIDatePicker) {
        let date = sender.date
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        UserDefaults.standard.set(hour, forKey: "EverydayNotificationHour")
        UserDefaults.standard.set(minute, forKey: "EverydayNotificationMinute")
        NotificationViewController.scheduleNotifications(hour, minute)
    }
    
    @objc func applicationDidBecomeActive() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) -> Void in
            if settings.authorizationStatus != .authorized {
                UserDefaults.standard.set(false, forKey: "EverydayNotification")
                self.isEverydayNotificationOn = false
            }
        })
    }
    
}

extension NotificationViewController {
    
    @IBAction func touchUpExitBarButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension NotificationViewController {
    static func refreshNotifications() {
        let isEverydayNotificationOn = UserDefaults.standard.bool(forKey: "EverydayNotification")
        if isEverydayNotificationOn {
            let hour = UserDefaults.standard.integer(forKey: "EverydayNotificationHour")
            let minute = UserDefaults.standard.integer(forKey: "EverydayNotificationMinute")
            scheduleNotifications(hour, minute)
        }
    }
    
    static func scheduleNotifications(_ hour: Int, _ minute: Int) {
        let goals = getGoals()
        guard goals.count > 0 else { return }
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        goals.forEach { goal in
            scheduleNotification(hour, minute, goal)
        }
    }
    
    static func scheduleNotification(_ hour: Int, _ minute: Int, _ goal: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "My 5Goals"
        content.body = goal
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    static func getGoals() -> [String] {
        let fetchedResultsController = FetchedResultsController(context: PersistentContainer.shared.viewContext, key: #keyPath(Goal.priority), delegate: nil, Goal.self)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        var goals: [String] = []
        fetchedResultsController.fetchedObjects?.forEach {
            guard let goal = $0 as? Goal else {
                return
            }
            goals.append("\(goal.priority + 1). \(goal.name!)")
        }
        return goals
    }
}
