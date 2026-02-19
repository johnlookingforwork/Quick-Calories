//
//  EditEntryView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entry: FoodEntry
    
    @State private var servings: Double
    @State private var showingSaveToSavedFoods = false
    @State private var didSaveFood = false
    
    private let originalCalories: Int
    private let originalProtein: Double
    private let originalCarbs: Double
    private let originalFat: Double
    
    init(entry: FoodEntry) {
        self.entry = entry
        self._servings = State(initialValue: entry.servings)
        
        self.originalCalories = Int(Double(entry.calories) / entry.servings)
        self.originalProtein = entry.protein / entry.servings
        self.originalCarbs = entry.carbs / entry.servings
        self.originalFat = entry.fat / entry.servings
    }
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        (
            calories: Int(Double(originalCalories) * servings),
            protein: originalProtein * servings,
            carbs: originalCarbs * servings,
            fat: originalFat * servings
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(entry.foodName)
                        .font(.headline)
                }
                
                Section("Servings") {
                    HStack {
                        Text("Servings")
                        Spacer()
                        TextField("1.0", value: $servings, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Stepper("", value: $servings, in: 0.1...20, step: 0.5)
                        .labelsHidden()
                }
                
                Section {
                    VStack(spacing: 16) {
                        // Calories
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("Calories")
                                .font(.headline)
                            Spacer()
                            Text("\(calculatedValues.calories)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        // Macros with circles
                        HStack(spacing: 20) {
                            MacroCircle(
                                name: "Protein",
                                value: calculatedValues.protein,
                                color: .red
                            )
                            
                            MacroCircle(
                                name: "Carbs",
                                value: calculatedValues.carbs,
                                color: .blue
                            )
                            
                            MacroCircle(
                                name: "Fat",
                                value: calculatedValues.fat,
                                color: .yellow
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Total Nutrition")
                }
                
                Section {
                    Button {
                        showingSaveToSavedFoods = true
                    } label: {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Add to Saved Foods")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if didSaveFood {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Saved for quick logging later!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Save this food for quick logging without AI in the future.")
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .sheet(isPresented: $showingSaveToSavedFoods) {
                SaveToSavedFoodsView(
                    foodName: entry.foodName,
                    calories: originalCalories,
                    protein: originalProtein,
                    carbs: originalCarbs,
                    fat: originalFat,
                    didSave: $didSaveFood
                )
            }
        }
    }
    
    private func saveChanges() {
        entry.servings = servings
        entry.calories = calculatedValues.calories
        entry.protein = calculatedValues.protein
        entry.carbs = calculatedValues.carbs
        entry.fat = calculatedValues.fat
        
        dismiss()
    }
}
struct MacroCircle: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Circle()
                    .strokeBorder(color, lineWidth: 3)
                    .frame(width: 70, height: 70)
                
                Text("\(Int(value))")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("grams")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

