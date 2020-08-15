//
//  Givingups.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import Foundation

class Givingups {
    static let shared: Givingups = Givingups()
    
    var givingups: [Givingup] = []
    
    private init() {}
}
