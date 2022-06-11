//
//  UserAction.swift
//  Five25Strategy
//
//  Created by 임성민 on 2021/06/29.
//  Copyright © 2021 SeongMin. All rights reserved.
//

import Foundation

enum UserAction {
    case add(Int)
    case delete(Int)
    case swipe(Int, SwipeDestination)
    case none
}

enum SwipeDestination {
    case goal
    case wish
    case givingUp
}
