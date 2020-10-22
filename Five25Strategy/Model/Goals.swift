//
//  Goals.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class Goals {
    static let shared: Goals = Goals()
    
    var goals: [Goal] = []
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    lazy var context = appDelegate?.persistentContainer.viewContext
    
    func resetPriority() {
        for (offset, goal) in self.goals.enumerated() {
            goal.priority = Int16(offset)
        }
    }
    
    func fetch() {
        if let context = self.context {
            do {
                self.goals = try context.fetch(Goal.fetchRequest())
                self.goals.sort { $0.priority < $1.priority }
            }
            catch let error as NSError {
                print("Could not fetch : \(error), \(error.userInfo)")
            }
        }
    }
    
    private init() {}
}
