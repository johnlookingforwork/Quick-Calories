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
    
    private func targetMet(_ date: Date) -> Bool {
        let netCals = caloriesForDate(date)
        let target = SettingsManager.shared.dailyCalorieTarget
        return netCals >= Int(Double(target) * 0.9) && netCals <= Int(Double(target) * 1.1)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    DayCard(
                        date: date,
                        calories: caloriesForDate(date),
                        target: SettingsManager.shared.dailyCalorieTarget,
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
        
        if percentage >= 0.9 && percentage <= 1.1 {
            return Color.green  // Hit goal (90-110%)
        } else if percentage >= 0.75 && percentage < 0.9 {
            return Color.orange  // Almost there (75-90%)
        } else {
            return Color.red  // Missed goal
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
