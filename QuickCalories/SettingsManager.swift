//
//  SettingsManager.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import Foundation
import Observation

@Observable
final class SettingsManager {
    static let shared = SettingsManager()
    
    var dailyCalorieTarget: Int = 2000 {
        didSet {
            UserDefaults.standard.set(dailyCalorieTarget, forKey: "dailyCalorieTarget")
        }
    }
    
    var proteinTarget: Double = 150.0 {
        didSet {
            UserDefaults.standard.set(proteinTarget, forKey: "proteinTarget")
        }
    }
    
    var carbsTarget: Double = 200.0 {
        didSet {
            UserDefaults.standard.set(carbsTarget, forKey: "carbsTarget")
        }
    }
    
    var fatTarget: Double = 67.0 {
        didSet {
            UserDefaults.standard.set(fatTarget, forKey: "fatTarget")
        }
    }
    
    var openAIApiKey: String? = nil {
        didSet {
            if let key = openAIApiKey {
                UserDefaults.standard.set(key, forKey: "openAIApiKey")
            } else {
                UserDefaults.standard.removeObject(forKey: "openAIApiKey")
            }
        }
    }
    
    var hasCompletedOnboarding: Bool = false {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    // Profile data for recalculation
    var userAge: Int = 0 {
        didSet {
            UserDefaults.standard.set(userAge, forKey: "userAge")
        }
    }
    
    var userWeight: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(userWeight, forKey: "userWeight")
        }
    }
    
    var userHeight: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(userHeight, forKey: "userHeight")
        }
    }
    
    var userGender: String = Gender.notSpecified.rawValue {
        didSet {
            UserDefaults.standard.set(userGender, forKey: "userGender")
        }
    }
    
    var activityLevel: String = ActivityLevel.moderate.rawValue {
        didSet {
            UserDefaults.standard.set(activityLevel, forKey: "activityLevel")
        }
    }
    
    var goalType: String = Goal.maintain.rawValue {
        didSet {
            UserDefaults.standard.set(goalType, forKey: "goalType")
        }
    }
    
    var macroSplitType: String = MacroSplit.balanced.rawValue {
        didSet {
            UserDefaults.standard.set(macroSplitType, forKey: "macroSplitType")
        }
    }
    
    var useMetricSystem: Bool = false {
        didSet {
            UserDefaults.standard.set(useMetricSystem, forKey: "useMetricSystem")
        }
    }
    
    // Free tier tracking
    var dailyAIRequestCount: Int = 0 {
        didSet {
            UserDefaults.standard.set(dailyAIRequestCount, forKey: "dailyAIRequestCount")
        }
    }
    
    var lastRequestResetDate: Date? = nil {
        didSet {
            UserDefaults.standard.set(lastRequestResetDate, forKey: "lastRequestResetDate")
        }
    }
    
    var hasActiveSubscription: Bool = false {
        didSet {
            UserDefaults.standard.set(hasActiveSubscription, forKey: "hasActiveSubscription")
        }
    }
    
    private init() {
        // Load saved values or use defaults
        let savedCalories = UserDefaults.standard.integer(forKey: "dailyCalorieTarget")
        self.dailyCalorieTarget = savedCalories > 0 ? savedCalories : 2000
        
        let savedProtein = UserDefaults.standard.double(forKey: "proteinTarget")
        self.proteinTarget = savedProtein > 0 ? savedProtein : 150
        
        let savedCarbs = UserDefaults.standard.double(forKey: "carbsTarget")
        self.carbsTarget = savedCarbs > 0 ? savedCarbs : 200
        
        let savedFat = UserDefaults.standard.double(forKey: "fatTarget")
        self.fatTarget = savedFat > 0 ? savedFat : 67
        
        self.openAIApiKey = UserDefaults.standard.string(forKey: "openAIApiKey")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.dailyAIRequestCount = UserDefaults.standard.integer(forKey: "dailyAIRequestCount")
        self.lastRequestResetDate = UserDefaults.standard.object(forKey: "lastRequestResetDate") as? Date
        self.hasActiveSubscription = UserDefaults.standard.bool(forKey: "hasActiveSubscription")
        
        // Load profile data
        self.userAge = UserDefaults.standard.integer(forKey: "userAge")
        self.userWeight = UserDefaults.standard.double(forKey: "userWeight")
        self.userHeight = UserDefaults.standard.double(forKey: "userHeight")
        self.userGender = UserDefaults.standard.string(forKey: "userGender") ?? Gender.notSpecified.rawValue
        self.activityLevel = UserDefaults.standard.string(forKey: "activityLevel") ?? ActivityLevel.moderate.rawValue
        self.goalType = UserDefaults.standard.string(forKey: "goalType") ?? Goal.maintain.rawValue
        self.macroSplitType = UserDefaults.standard.string(forKey: "macroSplitType") ?? MacroSplit.balanced.rawValue
        self.useMetricSystem = UserDefaults.standard.bool(forKey: "useMetricSystem")
        
        // Migration: If user has custom targets but hasn't "completed onboarding",
        // mark them as having completed it to skip onboarding for existing users
        if !self.hasCompletedOnboarding && savedCalories > 0 {
            self.hasCompletedOnboarding = true
        }
    }
    
    func checkAndResetDailyCount() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = lastRequestResetDate {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                dailyAIRequestCount = 0
                lastRequestResetDate = now
            }
        } else {
            lastRequestResetDate = now
        }
    }
    
    func canMakeAIRequest() -> Bool {
        checkAndResetDailyCount()
        
        // If user has their own API key or active subscription, no limit
        if openAIApiKey != nil || hasActiveSubscription {
            return true
        }
        
        // Free tier: 1 request per day
        return dailyAIRequestCount < 1
    }
    
    func incrementAIRequestCount() {
        dailyAIRequestCount += 1
    }
    
    /// Recalculate targets based on saved profile
    func recalculateFromProfile() {
        guard userAge > 0, userWeight > 0, userHeight > 0 else { return }
        
        guard let gender = Gender(rawValue: userGender),
              let activity = ActivityLevel(rawValue: activityLevel),
              let goal = Goal(rawValue: goalType) else { return }
        
        // Calculate new calorie target
        dailyCalorieTarget = CalorieCalculator.calculateDailyTarget(
            weight: userWeight,
            height: userHeight,
            age: userAge,
            gender: gender,
            activityLevel: activity,
            goal: goal
        )
        
        // Recalculate macros based on saved split type
        if let split = MacroSplit(rawValue: macroSplitType), split != .custom {
            let macros = split.calculateMacros(totalCalories: dailyCalorieTarget)
            proteinTarget = macros.protein
            carbsTarget = macros.carbs
            fatTarget = macros.fat
        }
    }
    
    var hasProfileData: Bool {
        userAge > 0 && userWeight > 0 && userHeight > 0
    }
}
