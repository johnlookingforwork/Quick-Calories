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
    @State private var editMode: EditMode = .servings
    
    // For direct macro editing
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    
    private let originalCalories: Int
    private let originalProtein: Double
    private let originalCarbs: Double
    private let originalFat: Double
    
    enum EditMode {
        case servings
        case manual
    }
    
    init(entry: FoodEntry) {
        self.entry = entry
        self._servings = State(initialValue: entry.servings)
        
        self.originalCalories = Int(Double(entry.calories) / entry.servings)
        self.originalProtein = entry.protein / entry.servings
        self.originalCarbs = entry.carbs / entry.servings
        self.originalFat = entry.fat / entry.servings
        
        // Initialize with current total values
        self._calories = State(initialValue: String(entry.calories))
        self._protein = State(initialValue: String(format: "%.1f", entry.protein))
        self._carbs = State(initialValue: String(format: "%.1f", entry.carbs))
        self._fat = State(initialValue: String(format: "%.1f", entry.fat))
    }
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        if editMode == .manual {
            return (
                calories: Int(calories) ?? 0,
                protein: Double(protein) ?? 0,
                carbs: Double(carbs) ?? 0,
                fat: Double(fat) ?? 0
            )
        } else {
            return (
                calories: Int(Double(originalCalories) * servings),
                protein: originalProtein * servings,
                carbs: originalCarbs * servings,
                fat: originalFat * servings
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(entry.foodName)
                        .font(.headline)
                }
                
                // Edit Mode Picker
                Section {
                    Picker("Edit Mode", selection: $editMode) {
                        Text("Servings").tag(EditMode.servings)
                        Text("Manual").tag(EditMode.manual)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Edit Mode")
                } footer: {
                    Text(editMode == .servings ? "Adjust the number of servings to scale the nutrition values proportionally." : "Manually edit each nutrition value independently.")
                }
                
                if editMode == .servings {
                    Section {
                        HStack {
                            Text("Servings")
                            Spacer()
                            
                            // Interactive servings control
                            HStack(spacing: 8) {
                                TextField("1.0", value: $servings, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .imageScale(.medium)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Stepper("Adjust servings", value: $servings, in: 0.1...20, step: 0.5)
                                .labelsHidden()
                        }
                    } footer: {
                        Text("Tap the number to type, or use +/- buttons to adjust")
                    }
                }
                
                if editMode == .manual {
                    Section("Nutrition") {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            Text("Calories")
                            Spacer()
                            TextField("0", text: $calories)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .fontWeight(.semibold)
                            Text("cal")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            Text("Protein")
                            Spacer()
                            TextField("0", text: $protein)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .fontWeight(.semibold)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text("Carbs")
                            Spacer()
                            TextField("0", text: $carbs)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .fontWeight(.semibold)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 24)
                            Text("Fat")
                            Spacer()
                            TextField("0", text: $fat)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .fontWeight(.semibold)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if editMode == .servings || (editMode == .manual && calculatedValues.calories > 0) {
                    Section {
                        VStack(spacing: 16) {
                            // Calories (read-only)
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
                            
                            // Macros with circles (read-only)
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
            .scrollDismissesKeyboard(.interactively)
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
        if editMode == .manual {
            // Save manual values
            entry.calories = Int(calories) ?? entry.calories
            entry.protein = Double(protein) ?? entry.protein
            entry.carbs = Double(carbs) ?? entry.carbs
            entry.fat = Double(fat) ?? entry.fat
            // Set servings to 1 since we're manually editing total values
            entry.servings = 1.0
        } else {
            // Save servings-based values
            entry.servings = servings
            entry.calories = calculatedValues.calories
            entry.protein = calculatedValues.protein
            entry.carbs = calculatedValues.carbs
            entry.fat = calculatedValues.fat
        }
        
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

