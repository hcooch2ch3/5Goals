//
//  PersistentContainer.swift
//  Five25Strategy
//
//  Created by 임성민 on 2021/06/15.
//  Copyright © 2021 SeongMin. All rights reserved.
//

import CoreData
import WidgetKit

final class PersistentContainer: NSPersistentContainer {
    
    static let shared = PersistentContainer()
    
    private let persistentStoreURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.PersistentContainer.groupIdentifier)?.appendingPathComponent(Constants.PersistentContainer.pathComponent)
    
    private convenience init() {
        self.init(name: Constants.PersistentContainer.name)
        
        guard let persistentStoreURL = self.persistentStoreURL else {
            return
        }

        if let previousStoreURL = persistentStoreDescriptions.first?.url,
           FileManager.default.fileExists(atPath: previousStoreURL.path) &&
            previousStoreURL.absoluteString != persistentStoreURL.absoluteString {
            migrate(from: previousStoreURL, to: persistentStoreURL)
            return
        }

        persistentStoreDescriptions = [NSPersistentStoreDescription(url: persistentStoreURL)]
        loadPersistentStores { persistentStoreDescription, error in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
        }
    }
    
    private func migrate(from oldStoreURL: URL, to newStoreURL: URL) {
        loadPersistentStores { persistentStoreDescription, error in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
        }
        
        guard let oldStore = persistentStoreCoordinator.persistentStore(for: oldStoreURL) else {
            return
        }
        do {
            try persistentStoreCoordinator.migratePersistentStore(oldStore, to: newStoreURL, options: nil, withType: NSSQLiteStoreType)
        } catch {
            print(error.localizedDescription)
        }
        
        // Delete old store.
        deleteStore(with: oldStoreURL)
    }
    
    private func deleteStore(with storeURL: URL) {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        fileCoordinator.coordinate(writingItemAt: storeURL, options: .forDeleting, error: nil, byAccessor: { url in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print(error.localizedDescription)
            }
        })
    }
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO: Adding Exception Handling
            }
            // TODO: Changing code to reload Widget if only goal is changed.
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
            }
        }
    }
    
}
