//
//  InfiniteDateScrollView.swift
//  QuickCalories
//
//  Created by John N on 2/20/26.
//

import SwiftUI
import SwiftData

struct InfiniteDateScrollView: View {
    @Query private var allEntries: [FoodEntry]
    @Query private var allWorkouts: [WorkoutEntry]
    @Query private var targetLogs: [DailyTargetLog]
    @Binding var selectedDate: Date

    var settings = SettingsManager.shared
    private let calendar = Calendar.current
    
    // Generate dates from 90 days ago to 30 days in the future
    private var dateRange: [Date] {
        let startOffset = -90
        let endOffset = 30
        
        return (startOffset...endOffset).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date()))
        }
    }
    
    private func entriesForDate(_ date: Date) -> [FoodEntry] {
        allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func workoutsForDate(_ date: Date) -> [WorkoutEntry] {
        allWorkouts.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func netCaloriesForDate(_ date: Date) -> Int {
        let foodCals = entriesForDate(date).reduce(0) { $0 + $1.calories }
        let workoutCals = workoutsForDate(date).reduce(0) { $0 + $1.caloriesBurned }
        return foodCals - workoutCals
    }
    
    private func targetForDate(_ date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        if let log = targetLogs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
            return log.calories
        }
        let priorLogs = targetLogs.filter { $0.date < dayStart }.sorted(by: { $0.date > $1.date })
        if let nearestPriorLog = priorLogs.first {
            return nearestPriorLog.calories
        }
        if let earliestLog = targetLogs.sorted(by: { $0.date < $1.date }).first {
            if dayStart < earliestLog.date {
                return earliestLog.calories
            }
        }
        return settings.dailyCalorieTarget
    }
    
    private func targetMet(_ date: Date) -> Bool {
        let netCals = netCaloriesForDate(date)
        if netCals == 0 { return false }
        
        let target = targetForDate(date)
        let pct = Double(netCals) / Double(target)
        
        let deviation: Double
        switch settings.dietMode {
        case .normal:
            deviation = abs(pct - 1.0)
        case .cut:
            deviation = max(0.0, pct - 1.0)
        case .bulk:
            deviation = max(0.0, 1.0 - pct)
        }
        
        return deviation <= 0.10
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(dateRange, id: \.self) { date in
                        InfiniteDateCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            calories: netCaloriesForDate(date),
                            target: targetForDate(date),
                            dietMode: settings.dietMode,
                            metGoal: targetMet(date),
                            hasData: !entriesForDate(date).isEmpty || !workoutsForDate(date).isEmpty
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = calendar.startOfDay(for: date)
                            }
                            
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                        .id(calendar.startOfDay(for: date))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .onAppear {
                // Scroll to selected date on appear
                proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                // Scroll to newly selected date with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(calendar.startOfDay(for: newValue), anchor: .center)
                }
            }
        }
    }
}

struct InfiniteDateCell: View {
    let date: Date
    let isSelected: Bool
    let calories: Int
    let target: Int
    let dietMode: DietMode
    let metGoal: Bool
    let hasData: Bool

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > Date()
    }

    private var statusColor: Color {
        if !hasData { return Color.gray.opacity(0.3) }
        let pct = Double(calories) / Double(target)
        
        let deviation: Double
        switch dietMode {
        case .normal:
            deviation = abs(pct - 1.0)
        case .cut:
            deviation = max(0.0, pct - 1.0)
        case .bulk:
            deviation = max(0.0, 1.0 - pct)
        }
        
        if deviation <= 0.10 {
            return .green
        } else if deviation <= 0.15 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Date number with circle
            ZStack {
                // Fill for selected date
                if isSelected {
                    Circle()
                        .fill(isToday ? Color.accentColor : statusColor)
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                }
                
                // Border ring
                if !isSelected {
                    Circle()
                        .strokeBorder(statusColor, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (isToday ? statusColor : .primary))
            }
            
            // Day label
            Text(date, format: .dateTime.weekday(.narrow))
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .opacity(isFuture && !hasData ? 0.5 : 1.0)
    }
}

#Preview {
    InfiniteDateScrollView(selectedDate: .constant(Date()))
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
