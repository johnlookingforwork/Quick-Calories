//
//  MonthlyHistoryView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct MonthlyHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    @Query private var allWorkouts: [WorkoutEntry]
    @State private var selectedDate: Date?
    @State private var currentMonth = Date()
    @State private var showAILog = false
    @State private var showSavedFoods = false
    @State private var showManualAdd = false
    @State private var showWorkoutLog = false
    @State private var selectedEntry: FoodEntry?
    @State private var selectedWorkout: WorkoutEntry?
    
    let initialDate: Date?
    
    init(initialDate: Date? = nil) {
        self.initialDate = initialDate
    }
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while days.count < 42 { // 6 weeks max
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func entriesForDate(_ date: Date) -> [FoodEntry] {
        allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func workoutsForDate(_ date: Date) -> [WorkoutEntry] {
        allWorkouts.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private func workoutCaloriesForDate(_ date: Date) -> Int {
        workoutsForDate(date).reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private func totalsForDate(_ date: Date) -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let entries = entriesForDate(date)
        return entries.reduce((0, 0.0, 0.0, 0.0)) { result, entry in
            (
                calories: result.calories + entry.calories,
                protein: result.protein + entry.protein,
                carbs: result.carbs + entry.carbs,
                fat: result.fat + entry.fat
            )
        }
    }
    
    private func metGoalForDate(_ date: Date) -> Bool {
        let totals = totalsForDate(date)
        let workoutCals = workoutCaloriesForDate(date)
        let netCalories = totals.calories - workoutCals
        let target = SettingsManager.shared.dailyCalorieTarget
        return netCalories >= Int(Double(target) * 0.9) && netCalories <= Int(Double(target) * 1.1)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(currentMonth, format: .dateTime.month(.wide).year())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            
            // Day headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            
            Divider()
            
            // Calendar grid
            ScrollView {
                VStack(spacing: 0) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(daysInMonth.indices, id: \.self) { index in
                            if let date = daysInMonth[index] {
                                DayCell(
                                    date: date,
                                    isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                                    isToday: calendar.isDateInToday(date),
                                    metGoal: metGoalForDate(date),
                                    hasEntries: !entriesForDate(date).isEmpty
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDate = date
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(height: 50)
                            }
                        }
                    }
                    .padding()
                
                // Selected day details
                if let selected = selectedDate {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                        
                        HStack {
                            Text(selected, style: .date)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if calendar.isDateInToday(selected) {
                                Text("Today")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                        
                        let totals = totalsForDate(selected)
                        let workoutCals = workoutCaloriesForDate(selected)
                        
                        // Daily summary
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calories")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(totals.calories)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    if workoutCals > 0 {
                                        Text("-\(workoutCals) workout")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(totals.protein))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(totals.carbs))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fat")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(totals.fat))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Meals for selected day
                        let entries = entriesForDate(selected)
                        if !entries.isEmpty {
                            Text("Meals")
                                .font(.headline)
                            
                            List {
                                ForEach(entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                    HStack(spacing: 12) {
                                        // Food icon
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.orange.gradient)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(entry.foodName)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            
                                            // Calories with flame icon
                                            HStack(spacing: 4) {
                                                Image(systemName: "flame.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.orange)
                                                Text("\(entry.calories) cal")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                            
                                            // Macros with icons
                                            HStack(spacing: 12) {
                                                // Protein
                                                HStack(spacing: 3) {
                                                    Image(systemName: "circle.fill")
                                                        .font(.system(size: 6))
                                                        .foregroundStyle(.red)
                                                    Text("\(Int(entry.protein))g")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                
                                                // Carbs
                                                HStack(spacing: 3) {
                                                    Image(systemName: "circle.fill")
                                                        .font(.system(size: 6))
                                                        .foregroundStyle(.blue)
                                                    Text("\(Int(entry.carbs))g")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                
                                                // Fat
                                                HStack(spacing: 3) {
                                                    Image(systemName: "circle.fill")
                                                        .font(.system(size: 6))
                                                        .foregroundStyle(.yellow)
                                                    Text("\(Int(entry.fat))g")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            if entry.servings != 1.0 {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "number.circle.fill")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text("\(entry.servings, specifier: "%.1f") servings")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Time on the right
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(entry.timestamp, style: .time)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(
                                        Color(uiColor: .secondarySystemBackground)
                                            .cornerRadius(12)
                                    )
                                    .listRowSeparator(.hidden)
                                    .onTapGesture {
                                        selectedEntry = entry
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteEntry(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            selectedEntry = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(entries.count) * 130)
                            .scrollDisabled(true)
                        }
                        
                        // Workouts for selected day
                        let workouts = workoutsForDate(selected)
                        if !workouts.isEmpty {
                            Text("Workouts")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            List {
                                ForEach(workouts.sorted(by: { $0.timestamp > $1.timestamp })) { workout in
                                    HStack(spacing: 12) {
                                        // Workout icon
                                        Image(systemName: "figure.run.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.green.gradient)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(workout.workoutName)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            
                                            // Calories burned
                                            HStack(spacing: 4) {
                                                Image(systemName: "flame.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                                Text("\(workout.caloriesBurned) cal burned")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Time on the right
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(workout.timestamp, style: .time)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding()
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(
                                        Color.green.opacity(0.1)
                                            .cornerRadius(12)
                                    )
                                    .listRowSeparator(.hidden)
                                    .onTapGesture {
                                        selectedWorkout = workout
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteWorkout(workout)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            selectedWorkout = workout
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(workouts.count) * 100)
                            .scrollDisabled(true)
                        }
                        
                        if entries.isEmpty && workouts.isEmpty {
                            Text("No meals or workouts logged")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Bottom padding to ensure FAB doesn't cover swipe actions
                if selectedDate != nil {
                    Color.clear
                        .frame(height: 80)
                }
            }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let date = initialDate {
                selectedDate = date
                currentMonth = date
            }
        }
        .sheet(isPresented: $showAILog) {
            if let date = selectedDate {
                AILogView(date: date)
            }
        }
        .sheet(isPresented: $showSavedFoods) {
            NavigationStack {
                SavedFoodsView()
            }
        }
        .sheet(isPresented: $showManualAdd) {
            if let date = selectedDate {
                ManualAddView(date: date)
            }
        }
        .sheet(isPresented: $showWorkoutLog) {
            if let date = selectedDate {
                LogWorkoutView(date: date)
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EditEntryView(entry: entry)
        }
        .sheet(item: $selectedWorkout) { workout in
            EditWorkoutView(workout: workout)
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDate != nil {
                // FAB only shows when a date is selected
                Menu {
                    Button {
                        showAILog = true
                    } label: {
                        Label("Log with AI", systemImage: "sparkles")
                    }
                    
                    Button {
                        showSavedFoods = true
                    } label: {
                        Label("Saved Foods", systemImage: "book")
                    }
                    
                    Button {
                        showManualAdd = true
                    } label: {
                        Label("Manual Add", systemImage: "keyboard")
                    }
                    
                    Button {
                        showWorkoutLog = true
                    } label: {
                        Label("Log Workout", systemImage: "figure.run")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        withAnimation {
            modelContext.delete(entry)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutEntry) {
        withAnimation {
            modelContext.delete(workout)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let metGoal: Bool
    let hasEntries: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .primary))
            
            if hasEntries {
                Circle()
                    .fill(metGoal ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        MonthlyHistoryView()
            .modelContainer(for: FoodEntry.self, inMemory: true)
    }
}
