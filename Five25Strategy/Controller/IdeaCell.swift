//
//  IdeaCell.swift
//  Five25Strategy
//
//  Created by 임성민 on 2022/03/01.
//  Copyright © 2022 SeongMin. All rights reserved.
//

import Foundation
import UIKit

class IdeaCell: UITableViewCell {
    @IBOutlet var ideaLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        if let button = actionButton {
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        }
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        if let button = actionButton {
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        editControlImageView?.tint(color: .black)
        reorderControlImageView?.tint(color: .black)
        editControlImageView?.tint(color: .black)
        verticalSeparator?.backgroundColor = .clear
    }
}
