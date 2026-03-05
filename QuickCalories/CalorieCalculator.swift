//
//  CalorieCalculator.swift
//  QuickCalories
//
//  Created by John N on 2/18/26.
//

import Foundation

enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case notSpecified = "Prefer not to say"
    
    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderate = "Moderately Active"
    case veryActive = "Very Active"
    case extremelyActive = "Extremely Active"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .sedentary:
            return "Little or no exercise"
        case .lightlyActive:
            return "Exercise 1-3 days/week"
        case .moderate:
            return "Exercise 3-5 days/week"
        case .veryActive:
            return "Exercise 6-7 days/week"
        case .extremelyActive:
            return "Physical job + training"
        }
    }
    
    var icon: String {
        switch self {
        case .sedentary:
            return "figure.seated.side"
        case .lightlyActive:
            return "figure.walk"
        case .moderate:
            return "figure.run"
        case .veryActive:
            return "figure.strengthtraining.traditional"
        case .extremelyActive:
            return "figure.basketball"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderate: return 1.55
        case .veryActive: return 1.725
        case .extremelyActive: return 1.9
        }
    }
}

enum Goal: String, CaseIterable, Identifiable {
    case loseWeight = "Lose Weight"
    case maintain = "Maintain Weight"
    case gainMuscle = "Gain Muscle"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .loseWeight:
            return "arrow.down.circle.fill"
        case .maintain:
            return "equal.circle.fill"
        case .gainMuscle:
            return "arrow.up.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .loseWeight:
            return "Create a calorie deficit"
        case .maintain:
            return "Balance calories in and out"
        case .gainMuscle:
            return "Create a calorie surplus"
        }
    }
    
    var calorieAdjustment: Double {
        switch self {
        case .loseWeight: return -500  // ~1 lb per week
        case .maintain: return 0
        case .gainMuscle: return 300   // Lean bulk
        }
    }
}

enum MacroSplit: String, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .balanced:
            return "1.6g protein/kg, balanced carbs & fats"
        case .highProtein:
            return "2.0g protein/kg, moderate carbs"
        case .lowCarb:
            return "1.8g protein/kg, low carbs, high fats"
        case .custom:
            return "Set your own values"
        }
    }
    
    var proteinPerKg: Double {
        switch self {
        case .balanced: return 1.6      // General population
        case .highProtein: return 2.0   // Athletes/muscle building
        case .lowCarb: return 1.8       // Low carb diets
        case .custom: return 0          // User defined
        }
    }
    
    /// Returns approximate percentage distribution for each macro
    var percentages: (protein: Double, carbs: Double, fat: Double) {
        switch self {
        case .balanced:
            return (protein: 0.30, carbs: 0.40, fat: 0.30)
        case .highProtein:
            return (protein: 0.35, carbs: 0.35, fat: 0.30)
        case .lowCarb:
            return (protein: 0.30, carbs: 0.20, fat: 0.50)
        case .custom:
            return (protein: 0.30, carbs: 0.40, fat: 0.30) // Default
        }
    }
    
    func calculateMacros(totalCalories: Int, bodyWeight: Double) -> (protein: Double, carbs: Double, fat: Double) {
        // Calculate protein based on body weight (scientifically accurate)
        let proteinGrams = proteinPerKg * bodyWeight
        let proteinCals = proteinGrams * 4.0
        
        // Calculate fat based on split type
        let fatPercentage: Double
        switch self {
        case .balanced: fatPercentage = 0.30       // 30% of calories
        case .highProtein: fatPercentage = 0.30    // 30% of calories
        case .lowCarb: fatPercentage = 0.50        // 50% of calories (keto-style)
        case .custom: fatPercentage = 0.30         // Default if custom
        }
        
        let fatCals = Double(totalCalories) * fatPercentage
        let fatGrams = fatCals / 9.0
        
        // Remaining calories go to carbs
        let remainingCals = Double(totalCalories) - proteinCals - fatCals
        let carbsGrams = max(0, remainingCals / 4.0)
        
        return (
            protein: proteinGrams,
            carbs: carbsGrams,
            fat: fatGrams
        )
    }
}

struct CalorieCalculator {
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
    static func calculateBMR(
        weight: Double,  // in kg
        height: Double,  // in cm
        age: Int,
        gender: Gender
    ) -> Double {
        switch gender {
        case .male:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        case .notSpecified:
            // Use average of male and female
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 78
        }
    }
    
    /// Calculate Total Daily Energy Expenditure
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }
    
    /// Adjust TDEE based on goal
    static func adjustForGoal(tdee: Double, goal: Goal) -> Double {
        return tdee + goal.calorieAdjustment
    }
    
    /// Calculate recommended daily calorie target
    static func calculateDailyTarget(
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel,
        goal: Goal
    ) -> Int {
        let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender)
        let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        let adjusted = adjustForGoal(tdee: tdee, goal: goal)
        return Int(adjusted)
    }
}

// MARK: - Unit Conversion Helpers

extension Double {
    /// Convert pounds to kilograms
    var lbsToKg: Double {
        self * 0.453592
    }
    
    /// Convert kilograms to pounds
    var kgToLbs: Double {
        self / 0.453592
    }
    
    /// Convert inches to centimeters
    var inchesToCm: Double {
        self * 2.54
    }
    
    /// Convert centimeters to inches
    var cmToInches: Double {
        self / 2.54
    }
}
