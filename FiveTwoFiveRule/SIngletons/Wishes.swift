//
//  Wishes.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import Foundation

class Wishes {
    static let shared: Wishes = Wishes()
    
    var wishes: [Wish] = []
    
    func resetPriority() {
        for (offset, wish) in self.wishes.enumerated() {
            wish.priority = Int16(offset)
        }
    }
    
    private init() {}
}
