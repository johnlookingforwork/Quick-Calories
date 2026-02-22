//
//  DashboardView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    @Query private var allWorkouts: [WorkoutEntry]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showPaywall = false
    @State private var showAILog = false
    @State private var showManualAdd = false
    @State private var showSavedFoods = false
    @State private var showWorkoutLog = false
    @State private var showDatePicker = false
    @State private var selectedEntry: FoodEntry?
    @State private var selectedWorkout: WorkoutEntry?
    @State private var navigateToSettings = false
    
    private let calendar = Calendar.current
    
    private var isViewingToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    private var displayDateEntries: [FoodEntry] {
        allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var displayDateWorkouts: [WorkoutEntry] {
        allWorkouts.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var displayDateWorkoutCalories: Int {
        displayDateWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private var displayDateTotals: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        displayDateEntries.reduce((0, 0.0, 0.0, 0.0)) { totals, entry in
            (totals.0 + entry.calories,
             totals.1 + entry.protein,
             totals.2 + entry.carbs,
             totals.3 + entry.fat)
        }
    }
    
    private var sectionTitle: String {
        if isViewingToday {
            return "Today's Meals"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: selectedDate)) Meals"
        }
    }
    
    private var workoutSectionTitle: String {
        if isViewingToday {
            return "Today's Workouts"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: selectedDate)) Workouts"
        }
    }
    
    private func jumpToToday() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = calendar.startOfDay(for: Date())
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Infinite Date Scroll with Dynamic Header
                    VStack(alignment: .leading, spacing: 12) {
                        DateHeaderView(
                            selectedDate: selectedDate,
                            onJumpToToday: jumpToToday
                        )
                        
                        InfiniteDateScrollView(selectedDate: $selectedDate)
                    }
                    .padding(.top, 8)
                    
                    // Daily Progress
                    DailyProgressView(
                        todayTotals: displayDateTotals,
                        workoutCalories: displayDateWorkoutCalories,
                        targets: (
                            calories: SettingsManager.shared.dailyCalorieTarget,
                            protein: SettingsManager.shared.proteinTarget,
                            carbs: SettingsManager.shared.carbsTarget,
                            fat: SettingsManager.shared.fatTarget
                        )
                    )
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.width < -50 && abs(value.translation.height) < 100 {
                                    // Swipe left - next day
                                    if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedDate = nextDay
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                } else if value.translation.width > 50 && abs(value.translation.height) < 100 {
                                    // Swipe right - previous day
                                    if let prevDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedDate = prevDay
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                }
                            }
                    )
                    
                    // Meals Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(sectionTitle)
                                .font(.headline)
                            
                            Spacer()
                            
                            if !displayDateEntries.isEmpty {
                                Text("Swipe to edit or delete")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if displayDateEntries.isEmpty {
                            Text("No meals logged yet")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            List {
                                ForEach(displayDateEntries) { entry in
                                    FoodEntryRow(entry: entry)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
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
                            .frame(height: CGFloat(displayDateEntries.count) * 130)
                            .scrollDisabled(true)
                        }
                    }
                    
                    // Workouts Section
                    if !displayDateWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(workoutSectionTitle)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("+\(displayDateWorkoutCalories) cal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal)
                            
                            List {
                                ForEach(displayDateWorkouts) { workout in
                                    WorkoutEntryRow(workout: workout)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
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
                            .frame(height: CGFloat(displayDateWorkouts.count) * 100)
                            .scrollDisabled(true)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("QuickCalories")
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EditEntryView(entry: entry)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showAILog) {
                AILogView(date: selectedDate)
            }
            .sheet(isPresented: $showManualAdd) {
                ManualAddView(date: selectedDate)
            }
            .sheet(isPresented: $showSavedFoods) {
                NavigationStack {
                    SavedFoodsView(logDate: selectedDate)
                }
            }
            .sheet(isPresented: $showWorkoutLog) {
                LogWorkoutView(date: selectedDate)
            }
            .sheet(item: $selectedWorkout) { workout in
                EditWorkoutView(workout: workout)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerPopup(selectedDate: $selectedDate)
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button with Menu
                Menu {
                    Button {
                        showAILog = true
                    } label: {
                        Label("Log with AI", systemImage: "sparkles")
                    }
                    
                    Button {
                        showManualAdd = true
                    } label: {
                        Label("Manual Add", systemImage: "plus.circle")
                    }
                    
                    Button {
                        showSavedFoods = true
                    } label: {
                        Label("Saved Foods", systemImage: "book")
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

struct DateHeaderView: View {
    let selectedDate: Date
    let onJumpToToday: () -> Void
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    private var isFuture: Bool {
        selectedDate > Date()
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if isToday {
                // Simple header when viewing today
                Text("Select Date")
                    .font(.headline)
                    .transition(.opacity)
            } else {
                // Date context when viewing other days
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                    
                    if isFuture {
                        Text("Logging for future date")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .transition(.opacity)
                
                Spacer()
                
                // Jump to Today button
                Button(action: onJumpToToday) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption2)
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .frame(minHeight: 44) // Consistent height
        .animation(.easeInOut(duration: 0.25), value: isToday)
    }
}

struct DailyProgressView: View {
    let todayTotals: (calories: Int, protein: Double, carbs: Double, fat: Double)
    let workoutCalories: Int
    let targets: (calories: Int, protein: Double, carbs: Double, fat: Double)
    
    private var caloriesRemaining: Int {
        targets.calories - todayTotals.calories + workoutCalories
    }
    
    private var calorieProgress: Double {
        Double(todayTotals.calories - workoutCalories) / Double(targets.calories)
    }
    
    // 10% grace period - only show red if over by more than 10%
    private var isOverBudget: Bool {
        caloriesRemaining < 0 && abs(caloriesRemaining) > Int(Double(targets.calories) * 0.1)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    // Center content
                    VStack(spacing: 4) {
                        Text("\(caloriesRemaining)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(isOverBudget ? Color.red : Color.primary)
                        
                        Text("calories remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if workoutCalories > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                        Text("+\(workoutCalories) from workouts")
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }
            }
            
            ProgressView(value: min(calorieProgress, 1.0))
                .tint(isOverBudget ? .red : .green)
            
            HStack(spacing: 16) {
                MacroProgressView(
                    name: "Protein",
                    current: todayTotals.protein,
                    target: targets.protein,
                    color: .red
                )
                
                MacroProgressView(
                    name: "Carbs",
                    current: todayTotals.carbs,
                    target: targets.carbs,
                    color: .blue
                )
                
                MacroProgressView(
                    name: "Fat",
                    current: todayTotals.fat,
                    target: targets.fat,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct MacroProgressView: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    
    @State private var isFlipped = false
    
    private var progress: Double {
        current / target
    }
    
    private var remaining: Double {
        max(target - current, 0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack {
                // Progress ring (background)
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Front side - Fraction style (current/target)
                VStack(spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(current))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text("g")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(width: 35, height: 1.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(target))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 90 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                // Back side - Remaining grams
                VStack(spacing: 2) {
                    Text("\(Int(remaining))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(remaining > 0 ? color : .green)
                    
                    Text("left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .frame(width: 80, height: 80)
            .contentShape(Circle())
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isFlipped.toggle()
                }
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    
    var body: some View {
        HStack(spacing: 12) {
            
            
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
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WorkoutEntryRow: View {
    let workout: WorkoutEntry
    
    var body: some View {
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
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
