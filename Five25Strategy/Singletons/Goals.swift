//
//  Goals.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import Foundation

class Goals {
    static let shared: Goals = Goals()
    
    var goals: [Goal] = []
    
    func resetPriority() {
        for (offset, goal) in self.goals.enumerated() {
            goal.priority = Int16(offset)
        }
    }
    
    private init() {}
}
