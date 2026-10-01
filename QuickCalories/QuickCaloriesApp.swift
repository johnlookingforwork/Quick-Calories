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
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
            SavedFood.self,
            WorkoutEntry.self,
            DailyTargetLog.self,
            Recipe.self,
            RecipeIngredient.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            print("✅ Initializing ModelContainer...")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("⚠️ Could not create persistent ModelContainer: \(error). Falling back to in-memory container.")
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    SettingsManager.shared.modelContainer = Self.sharedModelContainer
                    print("✅ ContentView appeared, SettingsManager modelContainer configured")
                }
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
