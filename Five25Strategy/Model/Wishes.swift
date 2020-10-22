//
//  Wishes.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class Wishes {
    static let shared: Wishes = Wishes()
    
    var wishes: [Wish] = []
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    lazy var context = appDelegate?.persistentContainer.viewContext
    
    func resetPriority() {
        for (offset, wish) in self.wishes.enumerated() {
            wish.priority = Int16(offset)
        }
    }
    
    func fetch() {
        if let context = self.context {
            do {
                self.wishes = try context.fetch(Wish.fetchRequest())
                self.wishes.sort { $0.priority < $1.priority }
            }
            catch let error as NSError {
                print("Could not fetch : \(error), \(error.userInfo)")
            }
        }
    }
    
    private init() {}
}
