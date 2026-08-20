//
//  StatsView.swift
//  QuickCalories
//
//  Created by John N on 8/12/26.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    @Query(sort: \DailyTargetLog.date, order: .forward) private var allTargetLogs: [DailyTargetLog]
    
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var healthSyncing = false
    @State private var weightHistory: [Date: Double] = [:]
    
    @State private var selectedWeightPoint: WeightChartPoint? = nil
    @State private var selectedCaloriePoint: CalorieChartPoint? = nil
    @State private var selectedTargetPoint: TargetChartPoint? = nil
    
    private var settings = SettingsManager.shared
    
    // Format weight helper for views
    private func formatWeight(_ w: Double) -> String {
        let displayVal = settings.useMetricSystem ? w : w.kgToLbs
        return String(format: "%.1f %@", displayVal, settings.useMetricSystem ? "kg" : "lbs")
    }
    
    // Group entries by date and get calories/macros for the last 30 days
    private var last30DaysDailyTotals: [Date: (calories: Int, protein: Double, carbs: Double, fat: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var totals: [Date: (calories: Int, protein: Double, carbs: Double, fat: Double)] = [:]
        
        // Initialize all 30 days with zeros
        for offset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                totals[date] = (0, 0.0, 0.0, 0.0)
            }
        }
        
        // Populate with entries
        for entry in allEntries {
            let entryDay = calendar.startOfDay(for: entry.timestamp)
            if let existing = totals[entryDay] {
                totals[entryDay] = (
                    calories: existing.calories + entry.calories,
                    protein: existing.protein + entry.protein,
                    carbs: existing.carbs + entry.carbs,
                    fat: existing.fat + entry.fat
                )
            }
        }
        
        return totals
    }
    
    // Filter days with >= 100 calories as active log days to prevent skewing the averages
    private var activeDaysSorted: [(date: Date, calories: Int, protein: Double, carbs: Double, fat: Double)] {
        last30DaysDailyTotals
            .map { (date: $0.key, calories: $0.value.calories, protein: $0.value.protein, carbs: $0.value.carbs, fat: $0.value.fat) }
            .filter { $0.calories >= 100 }
            .sorted { $0.date > $1.date } // Newest first
    }
    
    // Calculates average of first N active days
    private func getAverages(daysLimit: Int) -> (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        let activeSubset = Array(activeDaysSorted.prefix(daysLimit))
        guard !activeSubset.isEmpty else { return (0, 0.0, 0.0, 0.0, 0) }
        
        let sum = activeSubset.reduce((calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0)) { result, day in
            (
                calories: result.calories + day.calories,
                protein: result.protein + day.protein,
                carbs: result.carbs + day.carbs,
                fat: result.fat + day.fat
            )
        }
        
        let count = Double(activeSubset.count)
        return (
            calories: Int(Double(sum.calories) / count),
            protein: sum.protein / count,
            carbs: sum.carbs / count,
            fat: sum.fat / count,
            activeCount: activeSubset.count
        )
    }
    
    private var averages7Day: (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        getAverages(daysLimit: 7)
    }
    
    private var averages14Day: (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        getAverages(daysLimit: 14)
    }
    
    private var averages30Day: (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        getAverages(daysLimit: 30)
    }
    
    private var averagesForWindow: (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        getAverages(daysLimit: settings.metabolicWindowDays)
    }
    
    // Calorie maintenance (TDEE) based on target settings
    private var userTDEE: Int {
        let target = settings.dailyCalorieTarget
        if let goal = Goal(rawValue: settings.goalType) {
            return target - Int(goal.calorieAdjustment)
        }
        return target
    }
    
    // Rolling average of weight to smooth out daily fluctuations based on settings
    private var averageWeightSelectedDays: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = settings.weightAverageDays
        
        let lastDaysWeights = weightHistory.filter { (date, _) in
            let daysAgo = calendar.dateComponents([.day], from: date, to: today).day ?? 999
            return daysAgo >= 0 && daysAgo < days
        }.values
        
        if !lastDaysWeights.isEmpty {
            return lastDaysWeights.reduce(0.0, +) / Double(lastDaysWeights.count)
        }
        
        // Fallback to single latest weight if no history for the last N days
        return settings.userWeight
    }
    
    // Weight change trend analysis (kg) over the metabolic window
    private var weightChangeForWindow: Double? {
        guard !weightHistory.isEmpty else { return nil }
        return settings.calculateWeightChange(history: weightHistory, windowDays: settings.metabolicWindowDays)
    }
    
    // True calculated maintenance calories based on actual energy intake & weight changes
    private var adaptiveTDEE: Int {
        let windowDays = settings.metabolicWindowDays
        guard let wtChangeKg = weightChangeForWindow, averagesForWindow.calories > 0 else {
            return userTDEE
        }
        
        let calendar = Calendar.current
        let sortedDates = weightHistory.keys.sorted()
        guard let oldestDate = sortedDates.first, let newestDate = sortedDates.last else {
            return userTDEE
        }
        let daysGap = Double(calendar.dateComponents([.day], from: oldestDate, to: newestDate).day ?? windowDays)
        let days = max(Double(windowDays == 7 ? 3 : 7), daysGap)
        
        let wtChangeLbs = wtChangeKg * 2.20462
        let totalDeficit = wtChangeLbs * 3500.0
        let dailyDeficit = totalDeficit / days
        
        let tdee = Double(averagesForWindow.calories) - dailyDeficit
        return max(1200, min(5000, Int(tdee)))
    }
    
    // Suggested dynamic target based on remaining time and goal weight
    private var suggestedCalorieTarget: Int {
        let targetWeightKg = settings.targetWeight
        let targetDate = settings.targetDate
        let currentWeightKg = averageWeightSelectedDays
        
        guard targetWeightKg > 0, targetDate > Date(), currentWeightKg > 0 else {
            return settings.dailyCalorieTarget
        }
        
        let calendar = Calendar.current
        let daysRemaining = calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 30
        let weeksRemaining = max(1.0, Double(daysRemaining) / 7.0)
        
        let weightToLoseKg = currentWeightKg - targetWeightKg
        let weightToLoseLbs = weightToLoseKg * 2.20462
        let weeklyLbsTarget = weightToLoseLbs / weeksRemaining
        
        let dailyDeficit = (weeklyLbsTarget * 3500.0) / 7.0
        let suggested = Double(adaptiveTDEE) - dailyDeficit
        
        return max(1200, Int(suggested))
    }
    
    // Weight change projection (surplus or deficit relative to calculated maintenance TDEE)
    private var weightProjection: (value: Double, unit: String) {
        let avgCal = averages7Day.calories
        guard avgCal > 0 else { return (0.0, settings.useMetricSystem ? "kg" : "lbs") }
        
        let tdee = adaptiveTDEE
        let dailyDifference = Double(avgCal - tdee)
        
        // 3500 kcal surplus/deficit ~ 1 lb (0.45 kg) weight change
        let weeklyLbsChange = (dailyDifference * 7.0) / 3500.0
        let displayValue = settings.useMetricSystem ? weeklyLbsChange * 0.45359237 : weeklyLbsChange
        let unitStr = settings.useMetricSystem ? "kg" : "lbs"
        
        return (displayValue, unitStr)
    }
    
    // Chart Models
    struct WeightChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }
    
    struct CalorieChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let dayLabel: String
        let calories: Int
    }
    
    struct TargetChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let targetCalories: Int
    }
    
    private var weightChartData: [WeightChartPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return weightHistory
            .filter { (date, _) in
                let daysAgo = calendar.dateComponents([.day], from: date, to: today).day ?? 999
                return daysAgo >= 0 && daysAgo < 30
            }
            .map { WeightChartPoint(date: $0.key, weight: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var weightChartDomain: ClosedRange<Double> {
        let weights = weightChartData.map { settings.useMetricSystem ? $0.weight : $0.weight.kgToLbs }
        let target = settings.useMetricSystem ? settings.targetWeight : settings.targetWeight.kgToLbs
        
        let allValues = weights + [target]
        let minW = allValues.min() ?? 50.0
        let maxW = allValues.max() ?? 100.0
        
        let padding = (maxW - minW) * 0.15
        let lowerBound = max(0, minW - max(2.0, padding))
        let upperBound = maxW + max(2.0, padding)
        
        return lowerBound...upperBound
    }
    
    private var calorieChartData: [CalorieChartPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        var points: [CalorieChartPoint] = []
        for offset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let dayTotal = last30DaysDailyTotals[date]
                let cal = dayTotal?.calories ?? 0
                let label = formatter.string(from: date)
                points.append(CalorieChartPoint(date: date, dayLabel: label, calories: cal))
            }
        }
        return points
    }
    
    private var calorieChartMaxY: Int {
        let maxCal = calorieChartData.map { $0.calories }.max() ?? 2000
        let budget = settings.dailyCalorieTarget
        return max(budget + 500, maxCal + 200)
    }
    
    private var hasTargetHistory: Bool {
        !allTargetLogs.isEmpty
    }
    
    private var targetChartData: [TargetChartPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var points: [TargetChartPoint] = []
        
        // Sort logs by date to find earliest matching points
        let sortedLogs = allTargetLogs.sorted(by: { $0.date < $1.date })
        let earliestLog = sortedLogs.first
        
        for offset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let targetDay = calendar.startOfDay(for: date)
            
            if let match = sortedLogs.first(where: { calendar.isDate($0.date, inSameDayAs: targetDay) }) {
                points.append(TargetChartPoint(date: targetDay, targetCalories: match.calories))
            } else if let earliest = earliestLog, targetDay < earliest.date {
                // If the day is before our earliest target log, use the earliest log's values
                points.append(TargetChartPoint(date: targetDay, targetCalories: earliest.calories))
            } else {
                // Otherwise look backwards for the nearest prior log, or fall back to settings
                let priorLog = sortedLogs.last(where: { $0.date < targetDay })
                let fallbackTarget = priorLog?.calories ?? earliestLog?.calories ?? settings.dailyCalorieTarget
                points.append(TargetChartPoint(date: targetDay, targetCalories: fallbackTarget))
            }
        }
        
        return points
    }
    
    private var targetChartDomain: ClosedRange<Double> {
        let targets = targetChartData.map { Double($0.targetCalories) }
        let minT = targets.min() ?? 1200.0
        let maxT = targets.max() ?? 2500.0
        
        let padding = (maxT - minT) * 0.15
        let lowerBound = max(1000.0, minT - max(100.0, padding))
        let upperBound = maxT + max(100.0, padding)
        
        return lowerBound...upperBound
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Apple Health weight synchronization status panel
                HealthKitSyncView(
                    healthKitManager: healthKitManager,
                    settings: settings,
                    syncing: $healthSyncing,
                    onSyncTrigger: syncWeightFromHealth
                )
                
                // 1. Weight Goal Progress Section
                if settings.targetWeight > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight Goal Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            WeightProgressCard(
                                startWeight: settings.startWeight > 0 ? settings.startWeight : averageWeightSelectedDays,
                                currentWeight: averageWeightSelectedDays,
                                targetWeight: settings.targetWeight,
                                useMetric: settings.useMetricSystem,
                                averageDays: settings.weightAverageDays
                            )
                            
                            // Weight line graph
                            if !weightChartData.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let selected = selectedWeightPoint {
                                        Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)): **\(formatWeight(selected.weight))**")
                                            .font(.caption)
                                            .foregroundStyle(Color.accentColor)
                                            .transition(.opacity)
                                    } else {
                                        Text("Hold & drag graph to scrub values")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Chart {
                                        ForEach(weightChartData) { point in
                                            LineMark(
                                                x: .value("Date", point.date, unit: .day),
                                                y: .value("Weight", settings.useMetricSystem ? point.weight : point.weight.kgToLbs)
                                            )
                                            .foregroundStyle(Color.accentColor.gradient)
                                            .interpolationMethod(.catmullRom)
                                            .lineStyle(StrokeStyle(lineWidth: 3))
                                            
                                            PointMark(
                                                x: .value("Date", point.date, unit: .day),
                                                y: .value("Weight", settings.useMetricSystem ? point.weight : point.weight.kgToLbs)
                                            )
                                            .foregroundStyle(Color.accentColor)
                                            .symbolSize(30)
                                        }
                                        
                                        // Target reference line
                                        RuleMark(
                                            y: .value("Target", settings.useMetricSystem ? settings.targetWeight : settings.targetWeight.kgToLbs)
                                        )
                                        .foregroundStyle(.red)
                                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                                        .annotation(position: .top, alignment: .trailing) {
                                            Text("Target")
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                                .padding(.horizontal, 4)
                                                .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
                                        }
                                        
                                        // Scrubbing indicator
                                        if let selected = selectedWeightPoint {
                                            RuleMark(
                                                x: .value("Date", selected.date)
                                            )
                                            .foregroundStyle(.secondary.opacity(0.4))
                                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                            
                                            PointMark(
                                                x: .value("Date", selected.date),
                                                y: .value("Weight", settings.useMetricSystem ? selected.weight : selected.weight.kgToLbs)
                                            )
                                            .foregroundStyle(Color.accentColor)
                                            .symbolSize(100)
                                        }
                                    }
                                    .frame(height: 140)
                                    .chartYScale(domain: weightChartDomain)
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                            AxisGridLine()
                                            AxisValueLabel(format: .dateTime.day().month())
                                        }
                                    }
                                    .chartOverlay { proxy in
                                        GeometryReader { geo in
                                            Rectangle()
                                                .fill(.clear)
                                                .contentShape(Rectangle())
                                                .gesture(
                                                    DragGesture(minimumDistance: 0)
                                                        .onChanged { value in
                                                            let xLocation = value.location.x
                                                            if let date: Date = proxy.value(atX: xLocation) {
                                                                if let closest = weightChartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                                    selectedWeightPoint = closest
                                                                }
                                                            }
                                                        }
                                                        .onEnded { _ in
                                                            selectedWeightPoint = nil
                                                        }
                                                )
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Weekly Plan Recommendation")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                let dateStr = settings.targetDate.formatted(date: .abbreviated, time: .omitted)
                                let weightStr = settings.useMetricSystem ? String(format: "%.1f kg", settings.targetWeight) : String(format: "%.1f lbs", settings.targetWeight.kgToLbs)
                                
                                Text("To reach your target of **\(weightStr)** by **\(dateStr)**, we recommend eating **\(suggestedCalorieTarget) calories/day**.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if settings.useAdaptiveCalorieTarget {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .padding(.top, 1)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Auto-updating daily target enabled.")
                                                .font(.caption2)
                                                .foregroundStyle(.green)
                                                .fontWeight(.medium)
                                            if let lastUpdate = settings.lastTargetUpdateTime {
                                                Text("Last adjusted: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                Text("Last adjusted: recently")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
                
                // 1b. Calorie Target History Section (Only if adaptive targets enabled)
                if settings.useAdaptiveCalorieTarget {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Target History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let selected = selectedTargetPoint {
                                    Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)): **\(selected.targetCalories) cal**")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .transition(.opacity)
                                } else {
                                    if hasTargetHistory {
                                        Text("Hold & drag graph to scrub values")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("💡 Target history will show daily adjustments over time (currently showing preview)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Chart {
                                    ForEach(targetChartData) { point in
                                        LineMark(
                                            x: .value("Date", point.date, unit: .day),
                                            y: .value("Target", point.targetCalories)
                                        )
                                        .foregroundStyle(Color.orange.gradient)
                                        .interpolationMethod(.catmullRom)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        PointMark(
                                            x: .value("Date", point.date, unit: .day),
                                            y: .value("Target", point.targetCalories)
                                        )
                                        .foregroundStyle(.orange)
                                        .symbolSize(30)
                                    }
                                    
                                    // Scrubbing indicator
                                    if let selected = selectedTargetPoint {
                                        RuleMark(
                                            x: .value("Date", selected.date)
                                        )
                                        .foregroundStyle(.secondary.opacity(0.4))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                        
                                        PointMark(
                                            x: .value("Date", selected.date),
                                            y: .value("Target", selected.targetCalories)
                                        )
                                        .foregroundStyle(.orange)
                                        .symbolSize(100)
                                    }
                                }
                                .frame(height: 140)
                                .chartYScale(domain: targetChartDomain)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.day().month())
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geo in
                                        Rectangle()
                                            .fill(.clear)
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let xLocation = value.location.x
                                                        if let date: Date = proxy.value(atX: xLocation) {
                                                            if let closest = targetChartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                                selectedTargetPoint = closest
                                                            }
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        selectedTargetPoint = nil
                                                    }
                                            )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
                
                // 2. Calorie Intake & Trends Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calorie Intake & Trends")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        CalorieAvgCard(
                            title: "7-Day Avg",
                            calories: averages7Day.calories,
                            activeDays: averages7Day.activeCount,
                            totalDays: 7
                        )
                        
                        CalorieAvgCard(
                            title: "14-Day Avg",
                            calories: averages14Day.calories,
                            activeDays: averages14Day.activeCount,
                            totalDays: 14
                        )
                        
                        CalorieAvgCard(
                            title: "30-Day Avg",
                            calories: averages30Day.calories,
                            activeDays: averages30Day.activeCount,
                            totalDays: 30
                        )
                    }
                    .padding(.horizontal)
                    
                    // Calorie bar chart
                    if !calorieChartData.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            if let selected = selectedCaloriePoint {
                                Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)): **\(selected.calories) cal**")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                    .transition(.opacity)
                                    .padding(.horizontal)
                            } else {
                                Text("Hold & drag graph to scrub values")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                            
                            Chart {
                                ForEach(calorieChartData) { point in
                                    BarMark(
                                        x: .value("Day", point.dayLabel),
                                        y: .value("Calories", point.calories)
                                    )
                                    .foregroundStyle(Color.accentColor.gradient)
                                    .cornerRadius(4)
                                }
                                
                                // Daily budget line
                                RuleMark(
                                    y: .value("Budget", settings.dailyCalorieTarget)
                                )
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Budget")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 4)
                                        .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
                                }
                                
                                // Scrubbing highlight indicator
                                if let selected = selectedCaloriePoint {
                                    RuleMark(
                                        x: .value("Day", selected.dayLabel)
                                    )
                                    .foregroundStyle(.secondary.opacity(0.3))
                                }
                            }
                            .frame(height: 140)
                            .chartYScale(domain: 0...calorieChartMaxY)
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let xLocation = value.location.x
                                                    if let dayLabel: String = proxy.value(atX: xLocation) {
                                                        if let matched = calorieChartData.first(where: { $0.dayLabel == dayLabel }) {
                                                            selectedCaloriePoint = matched
                                                        }
                                                    }
                                                }
                                                .onEnded { _ in
                                                    selectedCaloriePoint = nil
                                                }
                                        )
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Daily Budget: **\(settings.dailyCalorieTarget) cal** (set in Settings)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if averages7Day.calories > 0 {
                            let diff = averages7Day.calories - averages30Day.calories
                            HStack(spacing: 6) {
                                Image(systemName: diff < 0 ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill")
                                    .foregroundStyle(diff < 0 ? .green : .orange)
                                Text(diff < 0
                                     ? "You are eating \(abs(diff)) calories/day less this week than your 30-day average."
                                     : "You are eating \(diff) calories/day more this week than your 30-day average.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                // 3. Metabolic Insights Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metabolic Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        // True Daily Burn Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("True Daily Burn (Metabolism)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(adaptiveTDEE) cal")
                                    .font(.headline)
                                    .foregroundStyle(Color.accentColor)
                            }
                            
                            Text("This is your actual metabolism (including BMR, daily steps, and workouts). It is how many calories you burn per day, calculated from your real-world weight changes and logged food over the last \(settings.metabolicWindowDays) days.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                        }
                        
                        Divider()
                        
                        // Projected Weight Trend Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Projected Weight Trend")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                
                                let proj = weightProjection
                                if proj.value == 0 {
                                    Text("Stable")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(String(format: "%+.1f %@", proj.value, proj.unit))
                                        .font(.headline)
                                        .foregroundStyle(proj.value < 0 ? .green : .orange)
                                }
                            }
                            
                            let proj = weightProjection
                            Text(proj.value < 0
                                 ? "Based on what you ate this week relative to your actual metabolism, you are on track to lose \(abs(proj.value).formatted(.number.precision(.fractionLength(1)))) \(proj.unit) per week."
                                 : proj.value > 0
                                 ? "Based on what you ate this week relative to your actual metabolism, you are on track to gain \(proj.value.formatted(.number.precision(.fractionLength(1)))) \(proj.unit) per week."
                                 : "Based on what you ate this week relative to your actual metabolism, your weight is projected to remain stable.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Nutrition Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncWeightAndHistory()
        }
    }
    
    private func syncWeightAndHistory() {
        if healthKitManager.isAuthorized {
            healthSyncing = true
            healthKitManager.fetchLatestWeight { _ in
                healthKitManager.fetchWeightHistory(daysLimit: 30) { history in
                    DispatchQueue.main.async {
                        healthSyncing = false
                        if let history = history {
                            self.weightHistory = history
                            
                            // Auto-populate starting weight with their weight 30 days ago if unset
                            if settings.startWeight == 0.0 {
                                if let oldestDate = history.keys.sorted().first,
                                   let oldestWeight = history[oldestDate] {
                                    settings.startWeight = oldestWeight
                                }
                            }
                            
                            settings.updateAdaptiveCalorieTarget(allEntries: allEntries)
                        }
                    }
                }
            }
        }
    }
    
    private func syncWeightFromHealth() {
        syncWeightAndHistory()
    }
}

// Visual weight goal progress card
struct WeightProgressCard: View {
    let startWeight: Double
    let currentWeight: Double
    let targetWeight: Double
    let useMetric: Bool
    let averageDays: Int
    
    private var formatWeight: (Double) -> String {
        return { w in
            let displayVal = useMetric ? w : w.kgToLbs
            return String(format: "%.1f %@", displayVal, useMetric ? "kg" : "lbs")
        }
    }
    
    private var progress: Double {
        let total = startWeight - targetWeight
        guard total != 0 else { return 0 }
        let currentLost = startWeight - currentWeight
        return max(0, min(1.0, currentLost / total))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Goal Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%% Complete", progress * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(formatWeight(startWeight))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Current (\(averageDays)-Day Avg): \(formatWeight(currentWeight))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatWeight(targetWeight))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("Uses a \(averageDays)-day average to smooth out daily water weight fluctuations.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }
}

// Apple Health Sync card view
struct HealthKitSyncView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let settings: SettingsManager
    @Binding var syncing: Bool
    let onSyncTrigger: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "heart.text.square.fill")
                .font(.title)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight Integration")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                if healthKitManager.isAuthorized {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Synced with Apple Health")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Auto-sync your weight for accurate TDEE calculations")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if healthKitManager.isAuthorized {
                Button {
                    onSyncTrigger()
                } label: {
                    if syncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(syncing)
            } else {
                Button("Connect") {
                    healthKitManager.requestPermission { _ in }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.caption)
                .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// Stats calorie average display tile
struct CalorieAvgCard: View {
    let title: String
    let calories: Int
    let activeDays: Int
    let totalDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("\(calories)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("\(activeDays)/\(totalDays) logged")
                .font(.caption2)
                .foregroundStyle(Color.accentColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .modelContainer(for: [FoodEntry.self, WorkoutEntry.self, DailyTargetLog.self], inMemory: true)
    }
}
