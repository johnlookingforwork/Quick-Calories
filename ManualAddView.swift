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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case foodName, calories, protein, carbs, fat
    }
    
    private var isValid: Bool {
        !foodName.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fat) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                        .focused($focusedField, equals: .foodName)
                }
                
                Section("Nutrition") {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField, equals: .calories)
                        Text("cal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                        Text("Protein")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField, equals: .protein)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.blue)
                        Text("Carbs")
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField, equals: .carbs)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                        Text("Fat")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField, equals: .fat)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Servings") {
                    HStack {
                        Text("How many servings?")
                        Spacer()
                        Text("\(servings, specifier: "%.1f")")
                            .foregroundStyle(.secondary)
                    }
                    
                    Stepper("", value: $servings, in: 0.1...20, step: 0.5)
                        .labelsHidden()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Manual Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                focusedField = .foodName
            }
        }
    }
    
    private func addEntry() {
        guard let caloriesValue = Int(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            return
        }
        
        let entry = FoodEntry(
            foodName: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue,
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
