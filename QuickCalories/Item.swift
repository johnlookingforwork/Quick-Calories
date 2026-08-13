//
//  FoodEntry.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var foodName: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var servings: Double
    var timestamp: Date
    var recipeDescription: String? = nil
    
    init(foodName: String, calories: Int, protein: Double, carbs: Double, fat: Double, servings: Double = 1.0, timestamp: Date = Date(), recipeDescription: String? = nil) {
        self.id = UUID()
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servings = servings
        self.timestamp = timestamp
        self.recipeDescription = recipeDescription
    }
}
@Model
final class SavedFood {
    var id: UUID
    var foodName: String
    var servingSize: Double
    var unit: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var createdAt: Date
    var orderIndex: Int = 0
    
    init(foodName: String, servingSize: Double, unit: String, calories: Int, protein: Double, carbs: Double, fat: Double, orderIndex: Int = 0) {
        self.id = UUID()
        self.foodName = foodName
        self.servingSize = servingSize
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }
}

@Model
final class WorkoutEntry {
    var id: UUID
    var workoutName: String
    var caloriesBurned: Int
    var timestamp: Date
    
    init(workoutName: String, caloriesBurned: Int, timestamp: Date = Date()) {
        self.id = UUID()
        self.workoutName = workoutName
        self.caloriesBurned = caloriesBurned
        self.timestamp = timestamp
    }
}

@Model
final class DailyTargetLog {
    var id: UUID
    var date: Date
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    
    init(date: Date, calories: Int, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    @MainActor
    static func ensureTargetLog(for date: Date, modelContext: ModelContext) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<DailyTargetLog>(
            predicate: #Predicate<DailyTargetLog> { log in
                log.date == targetDate
            }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            if results.isEmpty {
                let settings = SettingsManager.shared
                let newLog = DailyTargetLog(
                    date: targetDate,
                    calories: settings.dailyCalorieTarget,
                    protein: settings.proteinTarget,
                    carbs: settings.carbsTarget,
                    fat: settings.fatTarget
                )
                modelContext.insert(newLog)
                try modelContext.save()
                print("✅ SwiftData: Logged daily target for \(targetDate.formatted(date: .abbreviated, time: .omitted)): \(settings.dailyCalorieTarget) kcal")
            }
        } catch {
            print("❌ SwiftData: Error ensuring target log: \(error)")
        }
    }
    
    @MainActor
    static func saveOrUpdateTodayTargetLog(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DailyTargetLog>(
            predicate: #Predicate<DailyTargetLog> { log in
                log.date == today
            }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            let settings = SettingsManager.shared
            if let existing = results.first {
                existing.calories = settings.dailyCalorieTarget
                existing.protein = settings.proteinTarget
                existing.carbs = settings.carbsTarget
                existing.fat = settings.fatTarget
                print("✅ SwiftData: Updated today's target log: \(settings.dailyCalorieTarget) kcal")
            } else {
                let newLog = DailyTargetLog(
                    date: today,
                    calories: settings.dailyCalorieTarget,
                    protein: settings.proteinTarget,
                    carbs: settings.carbsTarget,
                    fat: settings.fatTarget
                )
                modelContext.insert(newLog)
                print("✅ SwiftData: Created today's target log: \(settings.dailyCalorieTarget) kcal")
            }
            try modelContext.save()
        } catch {
            print("❌ SwiftData: Error saving/updating today's target log: \(error)")
        }
    }
}

@Model
final class Recipe {
    var id: UUID
    var name: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [RecipeIngredient]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.ingredients = []
    }
    
    var totalCalories: Int {
        ingredients.reduce(0) { $0 + Int((Double($1.calories) * $1.servings).rounded()) }
    }
    
    var totalProtein: Double {
        ingredients.reduce(0.0) { $0 + ($1.protein * $1.servings) }
    }
    
    var totalCarbs: Double {
        ingredients.reduce(0.0) { $0 + ($1.carbs * $1.servings) }
    }
    
    var totalFat: Double {
        ingredients.reduce(0.0) { $0 + ($1.fat * $1.servings) }
    }
    
    var ingredientListSummary: String {
        ingredients.map { $0.foodName }.joined(separator: ", ")
    }
}

@Model
final class RecipeIngredient {
    var id: UUID
    var foodName: String
    var servings: Double
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var unit: String = "serving"
    
    init(foodName: String, servings: Double, calories: Int, protein: Double, carbs: Double, fat: Double, unit: String = "serving") {
        self.id = UUID()
        self.foodName = foodName
        self.servings = servings
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
    }
}

