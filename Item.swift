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
    
    init(foodName: String, calories: Int, protein: Double, carbs: Double, fat: Double, servings: Double = 1.0, timestamp: Date = Date()) {
        self.id = UUID()
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servings = servings
        self.timestamp = timestamp
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
    
    init(foodName: String, servingSize: Double, unit: String, calories: Int, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.foodName = foodName
        self.servingSize = servingSize
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = Date()
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

