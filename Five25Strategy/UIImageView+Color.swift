//
//  UIImageView+Color.swift
//  Five25Strategy
//
//  Created by 임성민 on 2022/03/01.
//  Copyright © 2022 SeongMin. All rights reserved.
//

import UIKit

extension UIImageView {
    func tint(color: UIColor) {
        self.image = self.image?.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
}
