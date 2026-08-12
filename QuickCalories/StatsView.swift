//
//  StatsView.swift
//  QuickCalories
//
//  Created by John N on 8/12/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var healthSyncing = false
    
    private var settings = SettingsManager.shared
    
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
    
    private var averages30Day: (calories: Int, protein: Double, carbs: Double, fat: Double, activeCount: Int) {
        getAverages(daysLimit: 30)
    }
    
    // Calorie maintenance (TDEE) based on target settings
    private var userTDEE: Int {
        let target = settings.dailyCalorieTarget
        if let goal = Goal(rawValue: settings.goalType) {
            return target - Int(goal.calorieAdjustment)
        }
        return target
    }
    
    // Adherence consistency score based on daily standard variance from target
    private var adherenceScore: (score: Int, rating: String) {
        let activeSubset = Array(activeDaysSorted.prefix(7))
        guard !activeSubset.isEmpty else { return (0, "No Logs") }
        
        let target = Double(settings.dailyCalorieTarget)
        let totalDeviation = activeSubset.reduce(0.0) { sum, day in
            sum + abs(Double(day.calories) - target)
        }
        
        let averageDeviation = totalDeviation / Double(activeSubset.count)
        let percentScore = max(0, 100 - Int((averageDeviation / target) * 100))
        
        let rating: String
        switch percentScore {
        case 90...100: rating = "Excellent"
        case 75..<90:  rating = "Good"
        case 50..<75:  rating = "Variable"
        default:       rating = "Inconsistent"
        }
        
        return (percentScore, rating)
    }
    
    // Weight change projection (surplus or deficit relative to maintenance TDEE)
    private var weightProjection: (value: Double, unit: String) {
        let avgCal = averages7Day.calories
        guard avgCal > 0 else { return (0.0, settings.useMetricSystem ? "kg" : "lbs") }
        
        let tdee = userTDEE
        let dailyDifference = Double(avgCal - tdee)
        
        // 3500 kcal surplus/deficit ~ 1 lb (0.45 kg) weight change
        let weeklyLbsChange = (dailyDifference * 7.0) / 3500.0
        let displayValue = settings.useMetricSystem ? weeklyLbsChange * 0.45359237 : weeklyLbsChange
        let unitStr = settings.useMetricSystem ? "kg" : "lbs"
        
        return (displayValue, unitStr)
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
                
                // Calorie comparison cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calorie Averages")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        CalorieAvgCard(
                            title: "7-Day Average",
                            calories: averages7Day.calories,
                            activeDays: averages7Day.activeCount,
                            totalDays: 7,
                            target: settings.dailyCalorieTarget
                        )
                        
                        CalorieAvgCard(
                            title: "30-Day Average",
                            calories: averages30Day.calories,
                            activeDays: averages30Day.activeCount,
                            totalDays: 30,
                            target: settings.dailyCalorieTarget
                        )
                    }
                    .padding(.horizontal)
                    
                    // Trend analysis text
                    if averages7Day.calories > 0 {
                        let diff = averages7Day.calories - averages30Day.calories
                        HStack(spacing: 6) {
                            Image(systemName: diff < 0 ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill")
                                .foregroundStyle(diff < 0 ? .green : .orange)
                            Text(diff < 0
                                 ? "You are eating \(abs(diff)) kcal/day less this week than your 30-day average."
                                 : "You are eating \(diff) kcal/day more this week than your 30-day average.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                
                // Macro Consistency Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("7-Day Macro Adherence")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        MacroProgressBar(
                            name: "Protein",
                            avg: averages7Day.protein,
                            target: settings.proteinTarget,
                            color: .red,
                            unit: "g"
                        )
                        
                        MacroProgressBar(
                            name: "Carbs",
                            avg: averages7Day.carbs,
                            target: settings.carbsTarget,
                            color: .blue,
                            unit: "g"
                        )
                        
                        MacroProgressBar(
                            name: "Fat",
                            avg: averages7Day.fat,
                            target: settings.fatTarget,
                            color: .yellow,
                            unit: "g"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                
                // Consistency Score and Projections
                VStack(alignment: .leading, spacing: 12) {
                    Text("Consistency & Projections")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Logging Consistency")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Based on variations from target")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(adherenceScore.score)% (\(adherenceScore.rating))")
                                .font(.headline)
                                .foregroundStyle(adherenceScore.score >= 75 ? .green : .orange)
                        }
                        
                        Divider()
                        
                        // Weekly projections card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Projected Weekly Change")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Based on surplus/deficit vs TDEE (\(userTDEE) cal)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
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
            syncWeightFromHealth()
        }
    }
    
    private func syncWeightFromHealth() {
        guard healthKitManager.isAuthorized else { return }
        healthSyncing = true
        healthKitManager.fetchLatestWeight { _ in
            healthSyncing = false
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
    let target: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("\(calories)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Target: \(target) cal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(activeDays) / \(totalDays) logged days")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// Styled linear macro progress tracker
struct MacroProgressBar: View {
    let name: String
    let avg: Double
    let target: Double
    let color: Color
    let unit: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, avg / target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.0f / %.0f %@", avg, target, unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.15))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .modelContainer(for: FoodEntry.self, inMemory: true)
    }
}
