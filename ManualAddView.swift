//
//  ManualAddView.swift
//  QuickCalories
//
//  Created by John N on 2/18/26.
//

import SwiftUI
import SwiftData

struct ManualAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servings = 1.0
    @State private var showingSaveToSavedFoods = false
    @State private var didSaveFood = false
    
    private var isValid: Bool {
        !foodName.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fat) != nil
    }
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double)? {
        guard let cal = Int(calories),
              let prot = Double(protein),
              let carb = Double(carbs),
              let f = Double(fat) else {
            return nil
        }
        
        return (
            calories: Int(Double(cal) * servings),
            protein: prot * servings,
            carbs: carb * servings,
            fat: f * servings
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                        .autocorrectionDisabled()
                }
                
                Section("Nutrition (per serving)") {
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
                
                Section("Servings") {
                    HStack {
                        Text("How many servings?")
                        Spacer()
                        TextField("1.0", value: $servings, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Stepper("", value: $servings, in: 0.1...20, step: 0.5)
                        .labelsHidden()
                }
                
                if let calculated = calculatedValues {
                    Section {
                        VStack(spacing: 16) {
                            // Calories
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("Calories")
                                    .font(.headline)
                                Spacer()
                                Text("\(calculated.calories)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Divider()
                            
                            // Macros with circles
                            HStack(spacing: 20) {
                                MacroCircle(
                                    name: "Protein",
                                    value: calculated.protein,
                                    color: .red
                                )
                                
                                MacroCircle(
                                    name: "Carbs",
                                    value: calculated.carbs,
                                    color: .blue
                                )
                                
                                MacroCircle(
                                    name: "Fat",
                                    value: calculated.fat,
                                    color: .yellow
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Total Nutrition")
                    }
                }
                
                if isValid {
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
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Manual Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logFood()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSaveToSavedFoods) {
                if let cal = Int(calories),
                   let prot = Double(protein),
                   let carb = Double(carbs),
                   let f = Double(fat) {
                    SaveToSavedFoodsView(
                        foodName: foodName,
                        calories: cal,
                        protein: prot,
                        carbs: carb,
                        fat: f,
                        didSave: $didSaveFood
                    )
                }
            }
        }
    }
    
    private func logFood() {
        guard let calculated = calculatedValues else { return }
        
        let entry = FoodEntry(
            foodName: foodName,
            calories: calculated.calories,
            protein: calculated.protein,
            carbs: calculated.carbs,
            fat: calculated.fat,
            servings: servings,
            timestamp: date
        )
        
        modelContext.insert(entry)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    ManualAddView(date: Date())
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
