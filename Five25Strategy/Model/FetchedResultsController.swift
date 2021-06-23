//
//  FetchedResultsController.swift
//  Five25Strategy
//
//  Created by 임성민 on 2021/06/18.
//  Copyright © 2021 SeongMin. All rights reserved.
//

import Foundation
import CoreData

final class FetchedResultsController<T: NSManagedObject>: NSFetchedResultsController<NSFetchRequestResult> {
    
    convenience init(context: NSManagedObjectContext, key: String, delegate: NSFetchedResultsControllerDelegate, _ managedObjectType: T.Type) {
        let fetchRequest = managedObjectType.fetchRequest()
        let sort = NSSortDescriptor(key: key, ascending: true)
        fetchRequest.sortDescriptors = [sort]
        self.init(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        self.delegate = delegate
    }
    
}
