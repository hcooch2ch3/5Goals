//
//  UITableViewCell+ImageViews.swift
//  Five25Strategy
//
//  Created by 임성민 on 2022/03/01.
//  Copyright © 2022 SeongMin. All rights reserved.
//

import UIKit

extension UITableViewCell {
    var reorderControlImageView: UIImageView? {
        let reorderControl = self.subviews.first { view -> Bool in
            view.classForCoder.description() == "UITableViewCellReorderControl"
        }
        return reorderControl?.subviews.first { view -> Bool in
            view is UIImageView
        } as? UIImageView
    }
    
    var editControlImageView: UIImageView? {
        let editControl = self.subviews.first { view -> Bool in
            view.classForCoder.description() == "UITableViewCellEditControl"
        }
        return editControl?.subviews.first { view -> Bool in
            view is UIImageView
        } as? UIImageView
    }
    
    var verticalSeparator: UIView? {
        let verticalSeparator = self.subviews.first { view -> Bool in
            view.classForCoder.description() == "_UITableViewCellVerticalSeparator"
        }
        return verticalSeparator
    }
    
    var actionButton: UIButton? {
        superview?.subviews
            .filter({ String(describing: $0).range(of: "UISwipeActionPullView") != nil })
            .flatMap({ $0.subviews })
            .filter({ String(describing: $0).range(of: "UISwipeActionStandardButton") != nil })
            .compactMap { $0 as? UIButton }.first
    }
}
