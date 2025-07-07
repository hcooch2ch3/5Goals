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

extension FontWeight {
    var weight: Font.Weight {
        switch self {
        case .thin:
            return .thin
        case .regular:
            return .regular
        case .semiBold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .unknown:
            return .bold
        }
    }
}

extension Font.Weight {
    var fontName: String {
        switch self {
        case .thin:
            return "NanumSquareNeoTTF-aLt"
        case .regular:
            return "NanumSquareNeoTTF-bRg"
        case .semibold:
            return "NanumSquareNeoTTF-cBd"
        case .bold:
            return "NanumSquareNeoTTF-dEb"
        case .heavy:
            return "NanumSquareNeoTTF-eHv"
        default:
            return "NanumSquareNeoTTF-dEb" // fallback
        }
    }
}

struct Provider: IntentTimelineProvider {
    typealias Intent = FontIntent
    typealias Entry = GoalEntry
     
    var managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func placeholder(in context: Context) -> GoalEntry {
        if var goals = try? self.managedObjectContext.fetch(Goal.fetchRequest()) {
            goals.sort { $0.priority < $1.priority }
            return GoalEntry(goals: goals, fontSize: 12, fontWeight: .bold)
        } else {
            return GoalEntry(goals: nil, fontSize: 12, fontWeight: .bold)
        }
    }
    
    func getSnapshot(for configuration: FontIntent, in context: Context, completion: @escaping (GoalEntry) -> Void) {
        let fontSize = CGFloat(truncating: configuration.fontsize ?? 12)
        let fontWeight = configuration.fontweight.weight
        if var goals = try? self.managedObjectContext.fetch(Goal.fetchRequest()) {
            goals.sort { $0.priority < $1.priority }
            let goalEntry = GoalEntry(goals: goals, fontSize: fontSize, fontWeight: fontWeight)
            completion(goalEntry)
        } else {
            let goalEntry = GoalEntry(goals: nil, fontSize: fontSize, fontWeight: fontWeight)
            completion(goalEntry)
        }
    }
    
    func getTimeline(for configuration: FontIntent, in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        let fontSize = CGFloat(truncating: configuration.fontsize ?? 12)
        let fontWeight = configuration.fontweight.weight
        if var goals = try? self.managedObjectContext.fetch(Goal.fetchRequest()) {
            goals.sort { $0.priority < $1.priority }
            let goalEntry = GoalEntry(goals: goals, fontSize: fontSize, fontWeight: fontWeight)
            let timeline = Timeline(entries: [goalEntry], policy: .never)
            completion(timeline)
        } else {
            let goalEntry = GoalEntry(goals: nil, fontSize: fontSize, fontWeight: fontWeight)
            let timeline = Timeline(entries: [goalEntry], policy: .never)
            completion(timeline)
        }
    }
}

struct GoalEntry: TimelineEntry {
    let date = Date()
    let goals: [Goal]?
    let fontSize: CGFloat
    let fontWeight: Font.Weight
}

struct GoalWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<5) { i in
                Text("\(i+1). \((entry.goals?.indices.contains(i) ?? false) ? (entry.goals?[i].name ?? "") : "")")
                    .font(.custom(entry.fontWeight.fontName, size: entry.fontSize))
                    .foregroundColor(.black)
                
            }
        }
        .padding(.all, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(hex: "#00FF00"))
    }
}

@main
struct GoalWidget: Widget {
    let kind: String = "GoalWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FontIntent.self, provider: Provider(context: persistentContainer.viewContext)) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("5Goals Widget")
        .description("This is your goal widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .disableContentMarginsIfNeeded()
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

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}
