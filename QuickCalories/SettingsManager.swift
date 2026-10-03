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

enum AdaptiveCalorieMode: String, CaseIterable, Identifiable, Codable {
    case disabled = "Disabled"
    case weightTrend = "Weight Trend"
    case calorieBudget = "Calorie Budget"
    
    var id: String { rawValue }
}

enum CalorieBudgetStyle: String, CaseIterable, Identifiable, Codable {
    case fixedWeekly = "Fixed Weekly Reset"
    case rolling7Day = "Rolling 7-Day Average"
    
    var id: String { rawValue }
}

enum WeekStartDay: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

enum PreservedMacroOption: String, CaseIterable, Identifiable, Codable {
    case none = "Scale All Ratios"
    case preserveProtein = "Preserve Protein Target"
    case preserveCarbs = "Preserve Carbs Target"
    case preserveFat = "Preserve Fat Target"
    
    var id: String { rawValue }
}

@Observable
final class SettingsManager {
    static let shared = SettingsManager()
    
    private var isInitializing = true
    
    var modelContainer: ModelContainer? = nil
    
    @MainActor
    func saveOrUpdateTodayTargetLog() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        DailyTargetLog.saveOrUpdateTodayTargetLog(modelContext: context)
    }
    
    var dailyCalorieTarget: Int = 2000 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(dailyCalorieTarget, forKey: "dailyCalorieTarget")
            if !useAdaptiveCalorieTarget {
                preAdaptiveCalorieTarget = dailyCalorieTarget
            }
        }
    }
    
    var proteinTarget: Double = 150.0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(proteinTarget, forKey: "proteinTarget")
            if !useAdaptiveCalorieTarget {
                preAdaptiveProteinTarget = proteinTarget
            }
        }
    }
    
    var carbsTarget: Double = 200.0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(carbsTarget, forKey: "carbsTarget")
            if !useAdaptiveCalorieTarget {
                preAdaptiveCarbsTarget = carbsTarget
            }
        }
    }
    
    var fatTarget: Double = 67.0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(fatTarget, forKey: "fatTarget")
            if !useAdaptiveCalorieTarget {
                preAdaptiveFatTarget = fatTarget
            }
        }
    }
    
    func updateBaseTargets(calories: Int, protein: Double, carbs: Double, fat: Double) {
        preAdaptiveCalorieTarget = calories
        preAdaptiveProteinTarget = protein
        preAdaptiveCarbsTarget = carbs
        preAdaptiveFatTarget = fat
        
        if !useAdaptiveCalorieTarget {
            dailyCalorieTarget = calories
            proteinTarget = protein
            carbsTarget = carbs
            fatTarget = fat
        } else {
            recalculateMacrosOnly()
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
    
    var adaptiveCalorieMode: AdaptiveCalorieMode = .disabled {
        didSet {
            guard !isInitializing else { return }
            guard adaptiveCalorieMode != oldValue else { return }
            UserDefaults.standard.set(adaptiveCalorieMode.rawValue, forKey: "adaptiveCalorieMode")
            UserDefaults.standard.set(adaptiveCalorieMode != .disabled, forKey: "useAdaptiveCalorieTarget")
            
            if oldValue == .disabled && adaptiveCalorieMode != .disabled {
                if preAdaptiveCalorieTarget == 0 {
                    preAdaptiveCalorieTarget = dailyCalorieTarget
                    preAdaptiveProteinTarget = proteinTarget
                    preAdaptiveCarbsTarget = carbsTarget
                    preAdaptiveFatTarget = fatTarget
                }
                recalculateMacrosOnly()
            } else if oldValue != .disabled && adaptiveCalorieMode == .disabled {
                dailyCalorieTarget = preAdaptiveCalorieTarget
                proteinTarget = preAdaptiveProteinTarget
                carbsTarget = preAdaptiveCarbsTarget
                fatTarget = preAdaptiveFatTarget
                saveOrUpdateTodayTargetLog()
            }
        }
    }
    
    var calorieBudgetStyle: CalorieBudgetStyle = .fixedWeekly {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(calorieBudgetStyle.rawValue, forKey: "calorieBudgetStyle")
        }
    }
    
    var weekStartDay: WeekStartDay = .monday {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(weekStartDay.rawValue, forKey: "weekStartDay")
        }
    }

    var preservedMacroOption: PreservedMacroOption = .none {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(preservedMacroOption.rawValue, forKey: "preservedMacroOption")
            if useAdaptiveCalorieTarget {
                recalculateMacrosOnly()
                saveOrUpdateTodayTargetLog()
            }
        }
    }

    var useAdaptiveCalorieTarget: Bool {
        get {
            adaptiveCalorieMode != .disabled
        }
        set {
            if newValue {
                if adaptiveCalorieMode == .disabled {
                    adaptiveCalorieMode = .weightTrend
                }
            } else {
                adaptiveCalorieMode = .disabled
            }
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
    
    var hiddenRecentFoods: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(hiddenRecentFoods), forKey: "hiddenRecentFoods")
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
    
    var autoCloseFoodMenu: Bool = true {
        didSet {
            UserDefaults.standard.set(autoCloseFoodMenu, forKey: "autoCloseFoodMenu")
        }
    }
    
    var preAdaptiveCalorieTarget: Int = 2000 {
        didSet {
            UserDefaults.standard.set(preAdaptiveCalorieTarget, forKey: "preAdaptiveCalorieTarget")
        }
    }
    
    var preAdaptiveProteinTarget: Double = 150.0 {
        didSet {
            UserDefaults.standard.set(preAdaptiveProteinTarget, forKey: "preAdaptiveProteinTarget")
        }
    }
    
    var preAdaptiveCarbsTarget: Double = 200.0 {
        didSet {
            UserDefaults.standard.set(preAdaptiveCarbsTarget, forKey: "preAdaptiveCarbsTarget")
        }
    }
    
    var preAdaptiveFatTarget: Double = 67.0 {
        didSet {
            UserDefaults.standard.set(preAdaptiveFatTarget, forKey: "preAdaptiveFatTarget")
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
        
        // Load preAdaptive baseline targets BEFORE adaptiveCalorieMode
        self.preAdaptiveCalorieTarget = UserDefaults.standard.integer(forKey: "preAdaptiveCalorieTarget")
        self.preAdaptiveProteinTarget = UserDefaults.standard.double(forKey: "preAdaptiveProteinTarget")
        self.preAdaptiveCarbsTarget = UserDefaults.standard.double(forKey: "preAdaptiveCarbsTarget")
        self.preAdaptiveFatTarget = UserDefaults.standard.double(forKey: "preAdaptiveFatTarget")
        
        if self.preAdaptiveCalorieTarget == 0 {
            self.preAdaptiveCalorieTarget = self.dailyCalorieTarget
            self.preAdaptiveProteinTarget = self.proteinTarget
            self.preAdaptiveCarbsTarget = self.carbsTarget
            self.preAdaptiveFatTarget = self.fatTarget
        }

        if let modeRaw = UserDefaults.standard.string(forKey: "adaptiveCalorieMode"),
           let mode = AdaptiveCalorieMode(rawValue: modeRaw) {
            self.adaptiveCalorieMode = mode
        } else {
            let legacyUseAdaptive = UserDefaults.standard.bool(forKey: "useAdaptiveCalorieTarget")
            self.adaptiveCalorieMode = legacyUseAdaptive ? .weightTrend : .disabled
        }
        
        if let styleRaw = UserDefaults.standard.string(forKey: "calorieBudgetStyle"),
           let style = CalorieBudgetStyle(rawValue: styleRaw) {
            self.calorieBudgetStyle = style
        } else {
            self.calorieBudgetStyle = .fixedWeekly
        }
        
        let savedWeekStart = UserDefaults.standard.integer(forKey: "weekStartDay")
        if savedWeekStart >= 1 && savedWeekStart <= 7 {
            self.weekStartDay = WeekStartDay(rawValue: savedWeekStart) ?? .monday
        } else {
            self.weekStartDay = .monday
        }
        
        if let preservedRaw = UserDefaults.standard.string(forKey: "preservedMacroOption"),
           let option = PreservedMacroOption(rawValue: preservedRaw) {
            self.preservedMacroOption = option
        } else {
            self.preservedMacroOption = .none
        }
        
        self.lastTargetUpdateTime = UserDefaults.standard.object(forKey: "lastTargetUpdateTime") as? Date
        self.metabolicWindowDays = UserDefaults.standard.integer(forKey: "metabolicWindowDays")
        if self.metabolicWindowDays == 0 {
            self.metabolicWindowDays = 14
        }
        self.isManualTarget = UserDefaults.standard.bool(forKey: "isManualTarget")
        self.pendingTargetUpdateAlert = UserDefaults.standard.string(forKey: "pendingTargetUpdateAlert")
        
        self.autoCloseFoodMenu = UserDefaults.standard.object(forKey: "autoCloseFoodMenu") != nil ? UserDefaults.standard.bool(forKey: "autoCloseFoodMenu") : true
        
        let savedWeightDays = UserDefaults.standard.integer(forKey: "weightAverageDays")
        self.weightAverageDays = savedWeightDays > 0 ? savedWeightDays : 5
        
        let savedHiddenRecents = UserDefaults.standard.stringArray(forKey: "hiddenRecentFoods") ?? []
        self.hiddenRecentFoods = Set(savedHiddenRecents)
        
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
        
        self.isInitializing = false
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
    
    /// Recalculates macronutrient targets while preserving designated macro if configured
    func recalculateMacrosOnly() {
        if useAdaptiveCalorieTarget {
            let baseCalories = preAdaptiveCalorieTarget > 0 ? preAdaptiveCalorieTarget : dailyCalorieTarget
            guard baseCalories > 0 else { return }
            
            switch preservedMacroOption {
            case .none:
                let baseProteinCal = preAdaptiveProteinTarget * 4.0
                let baseCarbsCal = preAdaptiveCarbsTarget * 4.0
                let baseFatCal = preAdaptiveFatTarget * 9.0
                let totalBaseCal = (baseProteinCal + baseCarbsCal + baseFatCal) > 0 ? (baseProteinCal + baseCarbsCal + baseFatCal) : Double(baseCalories)
                let scaleFactor = Double(dailyCalorieTarget) / totalBaseCal
                proteinTarget = max(0, (preAdaptiveProteinTarget * scaleFactor).rounded())
                carbsTarget = max(0, (preAdaptiveCarbsTarget * scaleFactor).rounded())
                fatTarget = max(0, (preAdaptiveFatTarget * scaleFactor).rounded())
                
            case .preserveProtein:
                proteinTarget = preAdaptiveProteinTarget
                let proteinCal = preAdaptiveProteinTarget * 4.0
                let remainingCal = max(0, Double(dailyCalorieTarget) - proteinCal)
                let baseCarbsCal = preAdaptiveCarbsTarget * 4.0
                let baseFatCal = preAdaptiveFatTarget * 9.0
                let baseOtherCal = baseCarbsCal + baseFatCal
                if baseOtherCal > 0 {
                    let carbsRatio = baseCarbsCal / baseOtherCal
                    let fatRatio = baseFatCal / baseOtherCal
                    carbsTarget = max(0, ((remainingCal * carbsRatio) / 4.0).rounded())
                    fatTarget = max(0, ((remainingCal * fatRatio) / 9.0).rounded())
                }
                
            case .preserveCarbs:
                carbsTarget = preAdaptiveCarbsTarget
                let carbsCal = preAdaptiveCarbsTarget * 4.0
                let remainingCal = max(0, Double(dailyCalorieTarget) - carbsCal)
                let baseProteinCal = preAdaptiveProteinTarget * 4.0
                let baseFatCal = preAdaptiveFatTarget * 9.0
                let baseOtherCal = baseProteinCal + baseFatCal
                if baseOtherCal > 0 {
                    let proteinRatio = baseProteinCal / baseOtherCal
                    let fatRatio = baseFatCal / baseOtherCal
                    proteinTarget = max(0, ((remainingCal * proteinRatio) / 4.0).rounded())
                    fatTarget = max(0, ((remainingCal * fatRatio) / 9.0).rounded())
                }
                
            case .preserveFat:
                fatTarget = preAdaptiveFatTarget
                let fatCal = preAdaptiveFatTarget * 9.0
                let remainingCal = max(0, Double(dailyCalorieTarget) - fatCal)
                let baseProteinCal = preAdaptiveProteinTarget * 4.0
                let baseCarbsCal = preAdaptiveCarbsTarget * 4.0
                let baseOtherCal = baseProteinCal + baseCarbsCal
                if baseOtherCal > 0 {
                    let proteinRatio = baseProteinCal / baseOtherCal
                    let carbsRatio = baseCarbsCal / baseOtherCal
                    proteinTarget = max(0, ((remainingCal * proteinRatio) / 4.0).rounded())
                    carbsTarget = max(0, ((remainingCal * carbsRatio) / 4.0).rounded())
                }
            }
        } else {
            if let split = MacroSplit(rawValue: macroSplitType) {
                if split != .custom {
                    let macros = split.calculateMacros(totalCalories: dailyCalorieTarget, bodyWeight: userWeight)
                    proteinTarget = macros.protein
                    carbsTarget = macros.carbs
                    fatTarget = macros.fat
                } else {
                    let currentMacroCalories = (proteinTarget * 4.0) + (carbsTarget * 4.0) + (fatTarget * 9.0)
                    guard currentMacroCalories > 0 else { return }
                    
                    let scaleFactor = Double(dailyCalorieTarget) / currentMacroCalories
                    proteinTarget = (proteinTarget * scaleFactor).rounded()
                    carbsTarget = (carbsTarget * scaleFactor).rounded()
                    fatTarget = (fatTarget * scaleFactor).rounded()
                }
            }
        }
    }
    
    var hasProfileData: Bool {
        userAge > 0 && userWeight > 0 && userHeight > 0
    }
}

extension SettingsManager {
    func updateAdaptiveCalorieTarget(allEntries: [FoodEntry]) {
        guard useAdaptiveCalorieTarget && adaptiveCalorieMode != .disabled else { return }
        
        switch adaptiveCalorieMode {
        case .disabled:
            return
        case .weightTrend:
            updateWeightTrendAdaptiveTarget(allEntries: allEntries)
        case .calorieBudget:
            updateCalorieBudgetAdaptiveTarget(allEntries: allEntries)
        }
    }
    
    private func updateCalorieBudgetAdaptiveTarget(allEntries: [FoodEntry]) {
        let baseTarget = preAdaptiveCalorieTarget > 0 ? preAdaptiveCalorieTarget : dailyCalorieTarget
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var suggested: Int = baseTarget
        
        switch calorieBudgetStyle {
        case .fixedWeekly:
            let weekStart = startOfWeek(for: today, weekStartDay: weekStartDay)
            let daysElapsed = max(0, calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0)
            let daysRemaining = max(1, 7 - (daysElapsed % 7))
            
            let consumedThisWeek = allEntries.reduce(0) { sum, entry in
                let entryDay = calendar.startOfDay(for: entry.timestamp)
                if entryDay >= weekStart && entryDay < today {
                    return sum + entry.calories
                }
                return sum
            }
            
            let totalWeeklyBudget = baseTarget * 7
            let remainingBudget = max(0, totalWeeklyBudget - consumedThisWeek)
            let rawSuggested = Double(remainingBudget) / Double(daysRemaining)
            
            let minAllowed = Double(max(1200, baseTarget - 600))
            let maxAllowed = Double(min(5000, baseTarget + 600))
            suggested = Int(max(minAllowed, min(maxAllowed, rawSuggested)))
            
        case .rolling7Day:
            guard let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }
            
            let past6DaysIntake = allEntries.reduce(0) { sum, entry in
                let entryDay = calendar.startOfDay(for: entry.timestamp)
                if entryDay >= sixDaysAgo && entryDay < today {
                    return sum + entry.calories
                }
                return sum
            }
            
            let total7DayBudget = baseTarget * 7
            let rawSuggested = Double(total7DayBudget - past6DaysIntake)
            
            let minAllowed = Double(max(1200, baseTarget - 600))
            let maxAllowed = Double(min(5000, baseTarget + 600))
            suggested = Int(max(minAllowed, min(maxAllowed, rawSuggested)))
        }
        
        let oldTarget = self.dailyCalorieTarget
        DispatchQueue.main.async {
            if suggested != self.dailyCalorieTarget || self.lastTargetUpdateTime == nil {
                self.dailyCalorieTarget = suggested
                self.recalculateMacrosOnly()
                self.lastTargetUpdateTime = Date()
                self.saveOrUpdateTodayTargetLog()
                
                if oldTarget > 0 && oldTarget != suggested {
                    let changeType = suggested > oldTarget ? "increase" : "decrease"
                    self.pendingTargetUpdateAlert = "Target updated from \(oldTarget) to \(suggested) cal based on your \(self.calorieBudgetStyle.rawValue) budget (\(changeType))"
                }
            }
        }
    }
    
    private func updateWeightTrendAdaptiveTarget(allEntries: [FoodEntry]) {
        guard targetWeight > 0 else { return }
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
                
                // Get calorie average over windowDays starting from yesterday (excluding today's incomplete logs):
                var totals: [Date: Int] = [:]
                for offset in 1...windowDays {
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
                let weightToLoseKg = currentWeight - self.targetWeight
                let weightToLoseLbs = weightToLoseKg * 2.20462
                
                var targetDailyDeficit: Double = 0.0
                if daysRemaining <= 0 {
                    if self.targetWeight > self.startWeight {
                        targetDailyDeficit = currentWeight >= self.targetWeight ? 0.0 : -300.0
                    } else {
                        targetDailyDeficit = currentWeight <= self.targetWeight ? 0.0 : 500.0
                    }
                } else {
                    let weeksRemaining = max(1.0, Double(daysRemaining) / 7.0)
                    let weeklyLbsTarget = weightToLoseLbs / weeksRemaining
                    targetDailyDeficit = (weeklyLbsTarget * 3500.0) / 7.0
                }
                
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
    
    /// Helper to find start of week for a given weekday
    func startOfWeek(for date: Date, weekStartDay: WeekStartDay) -> Date {
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: date)
        for _ in 0..<7 {
            if calendar.component(.weekday, from: current) == weekStartDay.rawValue {
                return current
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return calendar.startOfDay(for: date)
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
