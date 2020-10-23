//
//  GoalWidget.swift
//  GoalWidget
//
//  Created by 임성민 on 2020/10/01.
//  Copyright © 2020 SeongMin. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

struct Provider: IntentTimelineProvider {
    typealias Intent = SetFontSizeIntent
    typealias Entry = GoalEntry
     
    var managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func fontSize(for config: SetFontSizeIntent) -> Int {
        switch config.fontsize {
        case .xS:
            return 10
        case .s:
            return 12
        case .m:
            return 14
        case .l:
            return 16
        case .xL:
            return 18
        case .unknown:
            return 15
        }
    }
    
    func placeholder(in context: Context) -> GoalEntry {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals, fontSize: 15)
        }
        catch {
            entry = GoalEntry(goals: nil, fontSize: 15)
        }
        
        return entry!
    }
    
    func getSnapshot(for configuration: SetFontSizeIntent, in context: Context, completion: @escaping (GoalEntry) -> Void) {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals, fontSize: fontSize(for: configuration))
        }
        catch {
            entry = GoalEntry(goals: nil, fontSize: fontSize(for: configuration))
        }
        
        completion(entry!)
    }
    
    func getTimeline(for configuration: SetFontSizeIntent, in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        var goals: [Goal]? = nil
        var entry: GoalEntry? = nil
        
        do {
            goals = try self.managedObjectContext.fetch(Goal.fetchRequest())
            goals!.sort { $0.priority < $1.priority }
            entry = GoalEntry(goals: goals, fontSize: fontSize(for: configuration))
        }
        catch {
            entry = GoalEntry(goals: nil, fontSize: fontSize(for: configuration))
        }
        
        let timeline = Timeline(entries: [entry!], policy: .never)
        completion(timeline)
    }
}

struct GoalEntry: TimelineEntry {
    let date = Date()
    let goals: [Goal]?
    let fontSize: Int
}

struct GoalWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<5) { i in
                Text("\(i+1). \(entry.goals!.indices.contains(i) ? (entry.goals![i] as Goal).name! : String(repeating: " ", count: 30))")
                    .font(.system(size: CGFloat(entry.fontSize)))
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
        IntentConfiguration(kind: kind, intent: SetFontSizeIntent.self, provider: Provider(context: persistentContainer.viewContext)) { entry in
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
