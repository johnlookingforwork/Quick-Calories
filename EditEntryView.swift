//
//  EditEntryView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: FoodEntry
    
    @State private var servings: Double
    
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
                
                Section("Nutritional Values") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(calculatedValues.calories) cal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text("\(calculatedValues.protein, specifier: "%.1f")g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Carbs")
                        Spacer()
                        Text("\(calculatedValues.carbs, specifier: "%.1f")g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        Text("\(calculatedValues.fat, specifier: "%.1f")g")
                            .foregroundStyle(.secondary)
                    }
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
