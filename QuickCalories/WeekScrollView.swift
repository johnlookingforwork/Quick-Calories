//
//  WeekScrollView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct WeekScrollView: View {
    @Query private var allEntries: [FoodEntry]
    @Query private var allWorkouts: [WorkoutEntry]
    @Query private var targetLogs: [DailyTargetLog]
    @Binding var navigateToHistory: Bool
    @Binding var selectedHistoryDate: Date?
    
    private let calendar = Calendar.current
    
    private var last7Days: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date()))
        }.reversed()  // Most recent on the right
    }
    
    private func entriesForDate(_ date: Date) -> [FoodEntry] {
        allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func workoutsForDate(_ date: Date) -> [WorkoutEntry] {
        allWorkouts.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func caloriesForDate(_ date: Date) -> Int {
        let foodCals = entriesForDate(date).reduce(0) { $0 + $1.calories }
        let workoutCals = workoutsForDate(date).reduce(0) { $0 + $1.caloriesBurned }
        return foodCals - workoutCals
    }
    
    private func targetForDate(_ date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        
        // 1. Try to find a log matching the date
        if let log = targetLogs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
            return log.calories
        }
        
        // 2. Fallback to the latest log that is BEFORE the date (in case of gaps/non-logged days)
        let priorLogs = targetLogs.filter { $0.date < dayStart }.sorted(by: { $0.date > $1.date })
        if let nearestPriorLog = priorLogs.first {
            return nearestPriorLog.calories
        }
        
        // 3. Fallback to the earliest log if the date is BEFORE the earliest log
        if let earliestLog = targetLogs.sorted(by: { $0.date < $1.date }).first {
            if dayStart < earliestLog.date {
                return earliestLog.calories
            }
        }
        
        // 4. Fallback to active settings target
        return SettingsManager.shared.dailyCalorieTarget
    }
    
    private func targetMet(_ date: Date) -> Bool {
        let netCals = caloriesForDate(date)
        if netCals == 0 { return false }
        
        let target = targetForDate(date)
        let percentage = Double(netCals) / Double(target)
        let dietMode = SettingsManager.shared.dietMode
        
        let deviation: Double
        switch dietMode {
        case .normal:
            deviation = abs(percentage - 1.0)
        case .cut:
            deviation = max(0.0, percentage - 1.0)
        case .bulk:
            deviation = max(0.0, 1.0 - percentage)
        }
        
        return deviation <= 0.10
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    DayCard(
                        date: date,
                        calories: caloriesForDate(date),
                        target: targetForDate(date),
                        metGoal: targetMet(date)
                    )
                    .onTapGesture {
                        selectedHistoryDate = date
                        navigateToHistory = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

struct DayCard: View {
    let date: Date
    let calories: Int
    let target: Int
    let metGoal: Bool
    
    private let calendar = Calendar.current
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var statusColor: Color {
        if calories == 0 {
            return Color.gray.opacity(0.3)  // Empty/no data
        }
        
        let percentage = Double(calories) / Double(target)
        let dietMode = SettingsManager.shared.dietMode
        
        let deviation: Double
        switch dietMode {
        case .normal:
            deviation = abs(percentage - 1.0)
        case .cut:
            deviation = max(0.0, percentage - 1.0)
        case .bulk:
            deviation = max(0.0, 1.0 - percentage)
        }
        
        if deviation <= 0.10 {
            return Color.green  // Hit goal (within 10%)
        } else if deviation <= 0.15 {
            return Color.orange  // Almost there (within 15%)
        } else {
            return Color.red  // Missed goal (> 15%)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Date number with circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Circle()
                    .strokeBorder(statusColor, lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? statusColor : .primary)
            }
            
            // Day label
            Text(date, format: .dateTime.weekday(.narrow))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WeekScrollView(navigateToHistory: .constant(false), selectedHistoryDate: .constant(nil))
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
