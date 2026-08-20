//
//  SettingsManager.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import Foundation
import Observation
import HealthKit
import SwiftData

enum DietMode: String, CaseIterable {
    case normal = "Normal"
    case bulk   = "Bulk"
    case cut    = "Cut"
}

@Observable
final class SettingsManager {
    static let shared = SettingsManager()
    
    var modelContainer: ModelContainer? = nil
    
    @MainActor
    func saveOrUpdateTodayTargetLog() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        DailyTargetLog.saveOrUpdateTodayTargetLog(modelContext: context)
    }
    
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
    
    var hasAcceptedHealthDisclaimer: Bool = false {
        didSet {
            UserDefaults.standard.set(hasAcceptedHealthDisclaimer, forKey: "hasAcceptedHealthDisclaimer")
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
    
    var targetWeight: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(targetWeight, forKey: "targetWeight")
        }
    }
    
    var targetDate: Date = Date() {
        didSet {
            UserDefaults.standard.set(targetDate, forKey: "targetDate")
        }
    }
    
    var startWeight: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(startWeight, forKey: "startWeight")
        }
    }
    
    var startDate: Date = Date() {
        didSet {
            UserDefaults.standard.set(startDate, forKey: "startDate")
        }
    }
    
    var useAdaptiveCalorieTarget: Bool = false {
        didSet {
            UserDefaults.standard.set(useAdaptiveCalorieTarget, forKey: "useAdaptiveCalorieTarget")
        }
    }
    
    var lastTargetUpdateTime: Date? = nil {
        didSet {
            UserDefaults.standard.set(lastTargetUpdateTime, forKey: "lastTargetUpdateTime")
        }
    }
    
    var metabolicWindowDays: Int = 14 {
        didSet {
            UserDefaults.standard.set(metabolicWindowDays, forKey: "metabolicWindowDays")
        }
    }
    
    var isManualTarget: Bool = false {
        didSet {
            UserDefaults.standard.set(isManualTarget, forKey: "isManualTarget")
        }
    }
    
    var pendingTargetUpdateAlert: String? = nil {
        didSet {
            UserDefaults.standard.set(pendingTargetUpdateAlert, forKey: "pendingTargetUpdateAlert")
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

    var dietMode: DietMode = .normal {
        didSet {
            UserDefaults.standard.set(dietMode.rawValue, forKey: "dietMode")
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
    
    var weightAverageDays: Int = 5 {
        didSet {
            UserDefaults.standard.set(weightAverageDays, forKey: "weightAverageDays")
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
        self.hasAcceptedHealthDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedHealthDisclaimer")
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
        let savedDietMode = UserDefaults.standard.string(forKey: "dietMode") ?? ""
        self.dietMode = DietMode(rawValue: savedDietMode) ?? .normal
        
        // Load weight goal data
        self.targetWeight = UserDefaults.standard.double(forKey: "targetWeight")
        self.targetDate = UserDefaults.standard.object(forKey: "targetDate") as? Date ?? Date().addingTimeInterval(60 * 60 * 24 * 30)
        self.startWeight = UserDefaults.standard.double(forKey: "startWeight")
        self.startDate = UserDefaults.standard.object(forKey: "startDate") as? Date ?? Date()
        self.useAdaptiveCalorieTarget = UserDefaults.standard.bool(forKey: "useAdaptiveCalorieTarget")
        self.lastTargetUpdateTime = UserDefaults.standard.object(forKey: "lastTargetUpdateTime") as? Date
        self.metabolicWindowDays = UserDefaults.standard.integer(forKey: "metabolicWindowDays")
        if self.metabolicWindowDays == 0 {
            self.metabolicWindowDays = 14
        }
        self.isManualTarget = UserDefaults.standard.bool(forKey: "isManualTarget")
        self.pendingTargetUpdateAlert = UserDefaults.standard.string(forKey: "pendingTargetUpdateAlert")
        
        let savedWeightDays = UserDefaults.standard.integer(forKey: "weightAverageDays")
        self.weightAverageDays = savedWeightDays > 0 ? savedWeightDays : 5
        
        // Migration: Detect if they already had a manual target before this update
        if !UserDefaults.standard.bool(forKey: "hasConfiguredManualTargetFlag") {
            let gender = Gender(rawValue: self.userGender) ?? .notSpecified
            let activity = ActivityLevel(rawValue: self.activityLevel) ?? .moderate
            let goal = Goal(rawValue: self.goalType) ?? .maintain
            
            if self.userAge > 0 && self.userWeight > 0 && self.userHeight > 0 {
                let calculated = CalorieCalculator.calculateDailyTarget(
                    weight: self.userWeight,
                    height: self.userHeight,
                    age: self.userAge,
                    gender: gender,
                    activityLevel: activity,
                    goal: goal
                )
                // If their current target does not match BMR, mark it as manual!
                if self.dailyCalorieTarget != calculated {
                    self.isManualTarget = true
                }
            } else {
                // If profile is incomplete but they have a target, it's manual!
                if self.dailyCalorieTarget != 2000 {
                    self.isManualTarget = true
                }
            }
            UserDefaults.standard.set(true, forKey: "hasConfiguredManualTargetFlag")
        }
        
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
        
        let oldTarget = dailyCalorieTarget
        
        // Calculate new calorie target ONLY if not using adaptive target and target is not manual
        if !useAdaptiveCalorieTarget && !isManualTarget {
            let newTarget = CalorieCalculator.calculateDailyTarget(
                weight: userWeight,
                height: userHeight,
                age: userAge,
                gender: gender,
                activityLevel: activity,
                goal: goal
            )
            if newTarget != oldTarget {
                dailyCalorieTarget = newTarget
                let changeType = newTarget > oldTarget ? "increase" : "decrease"
                pendingTargetUpdateAlert = "From \(oldTarget) to \(newTarget) due to changes in weight \(changeType)"
            }
        }
        
        recalculateMacrosOnly()
        lastTargetUpdateTime = Date()
        saveOrUpdateTodayTargetLog()
    }
    
    /// Recalculates macronutrient targets while preserving ratios
    func recalculateMacrosOnly() {
        if let split = MacroSplit(rawValue: macroSplitType) {
            if split != .custom {
                let macros = split.calculateMacros(totalCalories: dailyCalorieTarget, bodyWeight: userWeight)
                proteinTarget = macros.protein
                carbsTarget = macros.carbs
                fatTarget = macros.fat
            } else {
                // For custom setups, scale grams proportionally to preserve macro ratios
                let currentMacroCalories = (proteinTarget * 4.0) + (carbsTarget * 4.0) + (fatTarget * 9.0)
                guard currentMacroCalories > 0 else { return }
                
                let scaleFactor = Double(dailyCalorieTarget) / currentMacroCalories
                proteinTarget = (proteinTarget * scaleFactor).rounded()
                carbsTarget = (carbsTarget * scaleFactor).rounded()
                fatTarget = (fatTarget * scaleFactor).rounded()
            }
        }
    }
    
    var hasProfileData: Bool {
        userAge > 0 && userWeight > 0 && userHeight > 0
    }
}

extension SettingsManager {
    func updateAdaptiveCalorieTarget(allEntries: [FoodEntry]) {
        guard useAdaptiveCalorieTarget && targetWeight > 0 else { return }
        
        let healthManager = HealthKitManager.shared
        guard healthManager.isAuthorized else { return }
        
        healthManager.fetchLatestWeight { currentWeight in
            healthManager.fetchWeightHistory(daysLimit: 30) { history in
                guard let history = history, let currentWeight = currentWeight else { return }
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                let windowDays = self.metabolicWindowDays
                let changeKg = self.calculateWeightChange(history: history, windowDays: windowDays)
                guard let changeKg = changeKg else { return }
                
                // Get calorie average over windowDays:
                var totals: [Date: Int] = [:]
                for offset in 0..<windowDays {
                    if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                        totals[date] = 0
                    }
                }
                for entry in allEntries {
                    let entryDay = calendar.startOfDay(for: entry.timestamp)
                    if let _ = totals[entryDay] {
                        totals[entryDay, default: 0] += entry.calories
                    }
                }
                let activeDaysCal = totals.values.filter { $0 >= 100 }
                guard !activeDaysCal.isEmpty else { return }
                let avgCalorieIntake = Double(activeDaysCal.reduce(0, +)) / Double(activeDaysCal.count)
                
                // TDEE calculation:
                let sortedDates = history.keys.sorted()
                let oldestDate = sortedDates.first!
                let newestDate = sortedDates.last!
                let daysGap = Double(calendar.dateComponents([.day], from: oldestDate, to: newestDate).day ?? windowDays)
                let days = max(Double(windowDays == 7 ? 3 : 7), daysGap)
                
                let wtChangeLbs = changeKg * 2.20462
                let totalDeficit = wtChangeLbs * 3500.0
                let dailyDeficit = totalDeficit / days
                
                let calculatedTDEE = avgCalorieIntake - dailyDeficit
                let constrainedTDEE = max(1200.0, min(5000.0, calculatedTDEE))
                
                // Deficit target projection:
                let daysRemaining = calendar.dateComponents([.day], from: Date(), to: self.targetDate).day ?? 30
                let weeksRemaining = max(1.0, Double(daysRemaining) / 7.0)
                let weightToLoseKg = currentWeight - self.targetWeight
                let weightToLoseLbs = weightToLoseKg * 2.20462
                let weeklyLbsTarget = weightToLoseLbs / weeksRemaining
                let targetDailyDeficit = (weeklyLbsTarget * 3500.0) / 7.0
                
                let suggested = max(1200, Int(constrainedTDEE - targetDailyDeficit))
                
                let oldTarget = self.dailyCalorieTarget
                DispatchQueue.main.async {
                    if suggested != self.dailyCalorieTarget || self.lastTargetUpdateTime == nil {
                        self.dailyCalorieTarget = suggested
                        self.recalculateMacrosOnly()
                        self.lastTargetUpdateTime = Date()
                        self.saveOrUpdateTodayTargetLog()
                        
                        if oldTarget > 0 && oldTarget != suggested {
                            let changeType = suggested > oldTarget ? "increase" : "decrease"
                            self.pendingTargetUpdateAlert = "From \(oldTarget) to \(suggested) due to changes in weight \(changeType)"
                        }
                    }
                }
            }
        }
    }
    
    /// Helper to calculate weight change dynamically with endpoint smoothing scaled to window size
    func calculateWeightChange(history: [Date: Double], windowDays: Int) -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let endWindowSize = windowDays == 7 ? 2 : 7
        let startWindowSize = windowDays == 7 ? 2 : 7
        
        var startWeights: [Double] = []
        var endWeights: [Double] = []
        
        for (date, weight) in history {
            let daysAgo = calendar.dateComponents([.day], from: date, to: today).day ?? 999
            if daysAgo >= 0 && daysAgo < endWindowSize {
                endWeights.append(weight)
            } else if daysAgo >= (windowDays - startWindowSize) && daysAgo < windowDays {
                startWeights.append(weight)
            }
        }
        
        if !startWeights.isEmpty && !endWeights.isEmpty {
            let avgStart = startWeights.reduce(0.0, +) / Double(startWeights.count)
            let avgEnd = endWeights.reduce(0.0, +) / Double(endWeights.count)
            return avgEnd - avgStart
        } else {
            // Fallback to raw oldest/newest within the window
            let sortedDates = history.keys.filter { date in
                let daysAgo = calendar.dateComponents([.day], from: date, to: today).day ?? 999
                return daysAgo >= 0 && daysAgo < windowDays
            }.sorted()
            
            guard sortedDates.count >= 2 else { return nil }
            if let oldest = history[sortedDates.first!], let newest = history[sortedDates.last!] {
                return newest - oldest
            }
            return nil
        }
    }
}
