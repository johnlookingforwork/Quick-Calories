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
    @Query private var allTargetLogs: [DailyTargetLog]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showPaywall = false
    @State private var showLoggingHub = false
    @State private var showWorkoutLog = false
    @State private var showDatePicker = false
    @State private var selectedEntry: FoodEntry?
    @State private var selectedWorkout: WorkoutEntry?
    @State private var navigateToSettings = false
    @State private var showingTargetUpdateAlert = false
    @State private var targetUpdateAlertMessage = ""

    @State private var settings = SettingsManager.shared
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
    
    private var displayDateTargets: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let targetDate = calendar.startOfDay(for: selectedDate)
        
        // 1. Try to find a log matching the selected date
        if let log = allTargetLogs.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            return (calories: log.calories, protein: log.protein, carbs: log.carbs, fat: log.fat)
        }
        
        // 2. Fallback to the earliest log if the selected date is BEFORE the earliest log
        if let earliestLog = allTargetLogs.sorted(by: { $0.date < $1.date }).first {
            if targetDate < earliestLog.date {
                return (calories: earliestLog.calories, protein: earliestLog.protein, carbs: earliestLog.carbs, fat: earliestLog.fat)
            }
        }
        
        // 3. Fallback to active settings targets
        return (
            calories: settings.dailyCalorieTarget,
            protein: settings.proteinTarget,
            carbs: settings.carbsTarget,
            fat: settings.fatTarget
        )
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
                        targets: displayDateTargets,
                        dietMode: settings.dietMode
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
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if !displayDateEntries.isEmpty {
                                Text("Swipe to edit or delete")
                                    .font(.system(size: 14))
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
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                            .frame(height: CGFloat(displayDateEntries.count) * 115)
                            .scrollDisabled(true)
                        }
                    }
                    
                    // Workouts Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(workoutSectionTitle)
                                .font(.headline)
                            
                            Spacer()
                            
                            if !displayDateWorkouts.isEmpty {
                                Text("+\(displayDateWorkoutCalories) cal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .padding(.trailing, 8)
                            }
                            
                            Button {
                                showWorkoutLog = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal)
                        
                        if !displayDateWorkouts.isEmpty {
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
                        } else {
                            HStack {
                                Text("No workouts logged for this day.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
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
                        StatsView()
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
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
            .sheet(isPresented: $showLoggingHub) {
                FoodLoggingHubView(date: selectedDate)
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
                // Floating Action Button directly launching the logging hub
                Button {
                    showLoggingHub = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .task {
                SettingsManager.shared.updateAdaptiveCalorieTarget(allEntries: allEntries)
                DailyTargetLog.saveOrUpdateTodayTargetLog(modelContext: modelContext)
            }
            .alert("Calorie Target Updated", isPresented: $showingTargetUpdateAlert) {
                Button("Got it", role: .cancel) {
                    settings.pendingTargetUpdateAlert = nil
                }
            } message: {
                Text(targetUpdateAlertMessage)
            }
            .onAppear {
                if let message = settings.pendingTargetUpdateAlert {
                    targetUpdateAlertMessage = message
                    showingTargetUpdateAlert = true
                }
            }
            .onChange(of: settings.pendingTargetUpdateAlert) { _, newValue in
                if let message = newValue {
                    targetUpdateAlertMessage = message
                    showingTargetUpdateAlert = true
                }
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
    let dietMode: DietMode

    @State private var showingCaloriesEaten = false

    private var caloriesRemaining: Int {
        targets.calories - todayTotals.calories + workoutCalories
    }

    private var calorieProgress: Double {
        Double(todayTotals.calories - workoutCalories) / Double(targets.calories)
    }

    private var isOverBudget: Bool {
        let tolerance = Int(Double(targets.calories) * 0.1)
        switch dietMode {
        case .normal, .cut:
            return caloriesRemaining < -tolerance
        case .bulk:
            return caloriesRemaining > tolerance
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    // Center content
                    VStack(spacing: 4) {
                        Text(showingCaloriesEaten ? "\(todayTotals.calories)" : "\(caloriesRemaining)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(isOverBudget ? Color.red : Color.primary)
                            .contentTransition(.numericText())

                        Text(showingCaloriesEaten ? "calories eaten" : "calories remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingCaloriesEaten.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            
            VStack(spacing: 6) {
                ProgressView(value: min(calorieProgress, 1.0))
                    .tint(isOverBudget ? .red : .green)
                
                HStack {
                    Text("0 cal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Target: \(targets.calories) cal")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            
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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Calories with flame icon
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(entry.calories) cal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                
                // Macros with dots
                HStack(spacing: 12) {
                    // Protein
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.red)
                        Text("\(Int(entry.protein))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Carbs
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                        Text("\(Int(entry.carbs))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Fat
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.yellow)
                        Text("\(Int(entry.fat))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let desc = entry.recipeDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                
                if entry.servings != 1.0 {
                    Text("\(entry.servings, specifier: "%.1f") servings")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(entry.timestamp, style: .time)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1.5)
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
        .modelContainer(for: [FoodEntry.self, WorkoutEntry.self, DailyTargetLog.self], inMemory: true)
}
