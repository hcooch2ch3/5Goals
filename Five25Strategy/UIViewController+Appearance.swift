//
//  UIViewController+Appearance.swift
//  Five25Strategy
//
//  Created by 임성민 on 2022/03/01.
//  Copyright © 2022 SeongMin. All rights reserved.
//

import UIKit

extension UIViewController {
    var topSpaceHeight: CGFloat {
        return (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) + (self.navigationController?.navigationBar.frame.size.height ?? 0)
    }
    
    var bottomSpaceHeight: CGFloat {
        return  (self.tabBarController?.tabBar.frame.size.height ?? 0)
    }
    
    func setNavigationBarClear() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
    }
    
    func setTabBarClear() {
        self.tabBarController?.tabBar.backgroundImage = UIImage()
        self.tabBarController?.tabBar.shadowImage = UIImage()
        self.tabBarController?.tabBar.barTintColor = .clear
        self.tabBarController?.view.backgroundColor = .clear
        self.tabBarController?.tabBar.isTranslucent = true
    }
}
