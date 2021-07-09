//
//  TabBarController.swift
//  Five25Strategy
//
//  Created by 임성민 on 2021/05/27.
//  Copyright © 2021 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class TabBarController: UITabBarController {

    func changeTabBarItemsState(to state: Bool) {
        guard let items = tabBar.items else {
            return
        }
        items.forEach { $0.isEnabled = state }
    }
    
    func refreshTabBarItemsBadge() {
        guard let items = tabBar.items else {
            return
        }
        if let goalCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Goal")) {
            items[0].badgeValue = goalCount > 0 ? String(goalCount) : nil
        }
        if let wishCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Wish")) {
            items[1].badgeValue = wishCount > 0 ? String(wishCount) : nil
        }
        if let givingupCount = try? PersistentContainer.shared.viewContext.count(for: NSFetchRequest(entityName: "Givingup")) {
            items[2].badgeValue = givingupCount > 0 ? String(givingupCount) : nil
        }
    }
    
    func moveTab(to index: Int) {
        guard let items = tabBar.items else {
            return
        }
        guard index < items.count else {
            return
        }
        selectedIndex = index
    }
    
    func moveTabToWishAndScrollToBottom() {
        if let viewControllers = self.viewControllers {
            if viewControllers.count > 1,
                let navigationController = viewControllers[1] as? UINavigationController {
                if let wishViewController = navigationController.viewControllers.first as? WishViewController {
                    wishViewController.isScrollToBottom = true
                }
            }
        }
        moveTab(to: 1)
    }
    
    var isWishViewControllerLoaded: Bool {
        if let viewControllers = self.viewControllers {
            if viewControllers.count > 1,
                let navigationController = viewControllers[1] as? UINavigationController {
                if let wishViewController = navigationController.viewControllers.first as? WishViewController {
                    return wishViewController.isViewLoaded
                }
            }
        }
        return false
    }
    
}
