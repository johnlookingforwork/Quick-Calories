//
//  AILogView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

// Wrapper to make NutritionResponse identifiable for sheet presentation
struct IdentifiableNutritionData: Identifiable {
    let id = UUID()
    let data: NutritionResponse
}

struct AILogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    @State private var foodInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var parsedNutrition: IdentifiableNutritionData?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date indicator
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Text input
                VStack(spacing: 12) {
                    TextEditor(text: $foodInput)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                        .overlay(
                            Group {
                                if foodInput.isEmpty {
                                    Text("Describe your meal...\ne.g., 3 scrambled eggs and sourdough toast")
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Log button
                Button(action: logFood) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Log with AI")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(foodInput.isEmpty || isLoading ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(foodInput.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Log with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $parsedNutrition) { wrapper in
                ConfirmAILogView(nutrition: wrapper.data, date: date)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func logFood() {
        guard !foodInput.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let nutrition = try await OpenAIService.shared.parseFood(foodInput)
                
                await MainActor.run {
                    isLoading = false
                    parsedNutrition = IdentifiableNutritionData(data: nutrition)
                }
            } catch OpenAIError.rateLimitExceeded {
                await MainActor.run {
                    isLoading = false
                    showPaywall = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ConfirmAILogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let nutrition: NutritionResponse
    let date: Date
    
    @State private var servings = 1.0
    @State private var showingSaveToSavedFoods = false
    @State private var didSaveFood = false
    @FocusState private var isServingsFocused: Bool
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        (
            calories: Int(Double(nutrition.calories) * servings),
            protein: nutrition.protein * servings,
            carbs: nutrition.carbs * servings,
            fat: nutrition.fat * servings
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutrition.foodName)
                            .font(.headline)
                        Text("From AI")
                            .font(.caption)
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
                            .focused($isServingsFocused)
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
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isServingsFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logFood()
                    }
                }
            }
            .sheet(isPresented: $showingSaveToSavedFoods) {
                SaveToSavedFoodsView(
                    foodName: nutrition.foodName,
                    calories: nutrition.calories,
                    protein: nutrition.protein,
                    carbs: nutrition.carbs,
                    fat: nutrition.fat,
                    didSave: $didSaveFood
                )
            }
        }
    }
    
    private func logFood() {
        let entry = FoodEntry(
            foodName: nutrition.foodName,
            calories: calculatedValues.calories,
            protein: calculatedValues.protein,
            carbs: calculatedValues.carbs,
            fat: calculatedValues.fat,
            servings: servings,
            timestamp: date
        )
        
        modelContext.insert(entry)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

struct SaveToSavedFoodsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    @Binding var didSave: Bool
    
    @State private var servingSize = "1"
    @State private var unit = "unit"
    
    private var isValid: Bool {
        Double(servingSize) != nil && !unit.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Name") {
                    Text(foodName)
                        .font(.body)
                }
                
                Section {
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit", text: $unit)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Serving Size")
                } footer: {
                    Text("Define 1 serving. You can adjust the number of servings when logging.")
                }
                
                Section("Nutrition (per serving)") {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text("Calories")
                        Spacer()
                        Text("\(calories)")
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
                        Text("\(protein, specifier: "%.1f")")
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
                        Text("\(carbs, specifier: "%.1f")")
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
                        Text("\(fat, specifier: "%.1f")")
                            .fontWeight(.semibold)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Save to Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFood()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveFood() {
        guard let servingSizeValue = Double(servingSize) else { return }
        
        let food = SavedFood(
            foodName: foodName,
            servingSize: servingSizeValue,
            unit: unit,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        modelContext.insert(food)
        didSave = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    AILogView(date: Date())
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
