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
    @State private var showPaywall = false
    @State private var showAILog = false
    @State private var showManualAdd = false
    @State private var showSavedFoods = false
    @State private var showWorkoutLog = false
    @State private var selectedEntry: FoodEntry?
    @State private var selectedWorkout: WorkoutEntry?
    @State private var navigateToHistory = false
    @State private var navigateToSettings = false
    @State private var selectedHistoryDate: Date?
    
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var todayWorkouts: [WorkoutEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allWorkouts.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var todayWorkoutCalories: Int {
        todayWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private var todayTotals: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        todayEntries.reduce((0, 0.0, 0.0, 0.0)) { totals, entry in
            (totals.0 + entry.calories,
             totals.1 + entry.protein,
             totals.2 + entry.carbs,
             totals.3 + entry.fat)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 7-Day Scrollable History
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        WeekScrollView(
                            navigateToHistory: $navigateToHistory,
                            selectedHistoryDate: $selectedHistoryDate
                        )
                    }
                    .padding(.top)
                    
                    // Daily Progress
                    DailyProgressView(
                        todayTotals: todayTotals,
                        workoutCalories: todayWorkoutCalories,
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
                                // Detect swipe left
                                if value.translation.width < -50 && abs(value.translation.height) < 100 {
                                    navigateToSettings = true
                                }
                            }
                    )
                    
                    // Today's Meals
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Meals")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !todayEntries.isEmpty {
                                Text("Swipe to edit or delete")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if todayEntries.isEmpty {
                            Text("No meals logged yet")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            List {
                                ForEach(todayEntries) { entry in
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
                            .frame(height: CGFloat(todayEntries.count) * 130) // Approximate height per row
                            .scrollDisabled(true)
                        }
                    }
                    
                    // Today's Workouts
                    if !todayWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Today's Workouts")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("+\(todayWorkoutCalories) cal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal)
                            
                            List {
                                ForEach(todayWorkouts) { workout in
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
                            .frame(height: CGFloat(todayWorkouts.count) * 100) // Approximate height per row
                            .scrollDisabled(true)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("QuickCalories")
            .navigationDestination(isPresented: $navigateToHistory) {
                if let date = selectedHistoryDate {
                    MonthlyHistoryView(initialDate: date)
                }
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MonthlyHistoryView()
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
                AILogView(date: Date())
            }
            .sheet(isPresented: $showManualAdd) {
                ManualAddView(date: Date())
            }
            .sheet(isPresented: $showSavedFoods) {
                NavigationStack {
                    SavedFoodsView()
                }
            }
            .sheet(isPresented: $showWorkoutLog) {
                LogWorkoutView(date: Date())
            }
            .sheet(item: $selectedWorkout) { workout in
                EditWorkoutView(workout: workout)
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
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    // Center content
                    VStack(spacing: 4) {
                        Text("\(caloriesRemaining)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(caloriesRemaining >= 0 ? Color.primary : Color.red)
                        
                        Text("calories remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Swipe hint (positioned absolutely on the right)
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text("edit")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.trailing, 4)
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
                .tint(caloriesRemaining >= 0 ? .green : .red)
            
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
