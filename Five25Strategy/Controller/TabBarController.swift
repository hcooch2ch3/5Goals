//
//  TabBarController.swift
//  Five25Strategy
//
//  Created by 임성민 on 2021/05/27.
//  Copyright © 2021 SeongMin. All rights reserved.
//

import UIKit

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
        items[0].badgeValue = Goals.shared.goals.count > 0 ? String(Goals.shared.goals.count) : nil
        items[1].badgeValue = Wishes.shared.wishes.count > 0 ? String(Wishes.shared.wishes.count) : nil
        items[2].badgeValue = Givingups.shared.givingups.count > 0 ? String(Givingups.shared.givingups.count) : nil
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
    
}
