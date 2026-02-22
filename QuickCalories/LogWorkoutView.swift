//
//  LogWorkoutView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    @State private var workoutName = ""
    @State private var caloriesBurned = ""
    @FocusState private var isCaloriesFocused: Bool
    
    private var isValid: Bool {
        !workoutName.isEmpty && Int(caloriesBurned) != nil && Int(caloriesBurned)! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout name (e.g., Morning Run)", text: $workoutName)
                    
                    HStack {
                        Text("Calories Burned")
                        Spacer()
                        TextField("0", text: $caloriesBurned)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($isCaloriesFocused)
                        Text("cal")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Text("Calories burned will be added to your remaining calories for the day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isCaloriesFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logWorkout()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func logWorkout() {
        guard let calories = Int(caloriesBurned) else { return }
        
        let workout = WorkoutEntry(
            workoutName: workoutName,
            caloriesBurned: calories,
            timestamp: date  // Use provided date
        )
        
        modelContext.insert(workout)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

struct EditWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    let workout: WorkoutEntry
    
    @State private var workoutName: String
    @State private var caloriesBurned: String
    @FocusState private var isCaloriesFocused: Bool
    
    init(workout: WorkoutEntry) {
        self.workout = workout
        _workoutName = State(initialValue: workout.workoutName)
        _caloriesBurned = State(initialValue: String(workout.caloriesBurned))
    }
    
    private var isValid: Bool {
        !workoutName.isEmpty && Int(caloriesBurned) != nil && Int(caloriesBurned)! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout name", text: $workoutName)
                    
                    HStack {
                        Text("Calories Burned")
                        Spacer()
                        TextField("0", text: $caloriesBurned)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($isCaloriesFocused)
                        Text("cal")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isCaloriesFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let calories = Int(caloriesBurned) else { return }
        
        workout.workoutName = workoutName
        workout.caloriesBurned = calories
        
        dismiss()
    }
}

#Preview {
    LogWorkoutView(date: Date())
        .modelContainer(for: WorkoutEntry.self, inMemory: true)
}
