//
//  Givingups.swift
//  FiveTwoFiveRule
//
//  Created by 임성민 on 2020/08/15.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import UIKit
import CoreData

class Givingups {
    static let shared: Givingups = Givingups()
    
    var givingups: [Givingup] = []
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    lazy var context = appDelegate?.persistentContainer.viewContext
    
    func resetPriority() {
        for (offset, givingup) in self.givingups.enumerated() {
            givingup.priority = Int16(offset)
        }
    }
    
    func fetch() {
        if let context = self.context {
            do {
                self.givingups = try context.fetch(Givingup.fetchRequest())
                self.givingups.sort { $0.priority < $1.priority }
            }
            catch let error as NSError {
                print("Could not fetch : \(error), \(error.userInfo)")
            }
        }
    }
    
    private init() {}
}
