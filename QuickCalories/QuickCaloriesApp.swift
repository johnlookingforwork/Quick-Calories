//
//  QuickCaloriesApp.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

@main
struct QuickCaloriesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
            SavedFood.self,
            WorkoutEntry.self,
            DailyTargetLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            print("✅ Initializing ModelContainer...")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("❌ FATAL: Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        print("✅ QuickCaloriesApp initializing...")
        SettingsManager.shared.modelContainer = sharedModelContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✅ ContentView appeared")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
