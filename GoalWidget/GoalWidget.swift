//
//  GoalWidget.swift
//  GoalWidget
//
//  Created by 임성민 on 2020/10/01.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    typealias Entry = GoalEntry
    
    var managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func placeholder(in context: Context) -> GoalEntry {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals)
        }
        catch {
            entry = GoalEntry(goals: nil)
        }
        
        return entry!
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals)
        }
        catch {
            entry = GoalEntry(goals: nil)
        }
        
        completion(entry!)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals)
        }
        catch {
            entry = GoalEntry(goals: nil)
        }
        
        let timeline = Timeline(entries: [entry!], policy: .never)
        completion(timeline)
    }
}

struct GoalEntry: TimelineEntry {
    let date = Date()
    let goals: [Goal]?
}

struct GoalWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<5) { i in
                Text("\(i+1). \(entry.goals!.indices.contains(i) ? (entry.goals![i] as Goal).name! : String(repeating: " ", count: 30))")
                    .font(.system(size: 15))
                    .foregroundColor(Color.green)
            }
        }
        .padding(.all, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
    }
    
}

@main
struct GoalWidget: Widget {
    let kind: String = "GoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(context: persistentContainer.viewContext)) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("5/25 Strategy Widget")
        .description("This is your goal widget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Five25Strategy")
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.SM.Five25Strategy")!.appendingPathComponent("Five25Strategy.sqlite")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

}
