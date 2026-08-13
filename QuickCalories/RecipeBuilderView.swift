//
//  RecipeBuilderView.swift
//  QuickCalories
//
//  Created by John N on 8/13/26.
//

import SwiftUI
import SwiftData

struct RecipeBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \SavedFood.foodName) private var savedFoods: [SavedFood]
    
    let recipeToEdit: Recipe?
    
    @State private var recipeName: String
    @State private var selectedIngredients: [RecipeIngredientState]
    @State private var showIngredientSelector = false
    
    init(recipeToEdit: Recipe? = nil) {
        self.recipeToEdit = recipeToEdit
        if let recipe = recipeToEdit {
            self._recipeName = State(initialValue: recipe.name)
            self._selectedIngredients = State(initialValue: recipe.ingredients.map {
                RecipeIngredientState(
                    foodName: $0.foodName,
                    servings: $0.servings,
                    calories: $0.calories,
                    protein: $0.protein,
                    carbs: $0.carbs,
                    fat: $0.fat,
                    unit: $0.unit
                )
            })
        } else {
            self._recipeName = State(initialValue: "")
            self._selectedIngredients = State(initialValue: [])
        }
    }
    
    struct RecipeIngredientState: Identifiable {
        let id = UUID()
        let foodName: String
        var servings: Double
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String
    }
    
    private var totalCalories: Int {
        selectedIngredients.reduce(0) { $0 + Int((Double($1.calories) * $1.servings).rounded()) }
    }
    
    private var totalProtein: Double {
        selectedIngredients.reduce(0.0) { $0 + ($1.protein * $1.servings) }
    }
    
    private var totalCarbs: Double {
        selectedIngredients.reduce(0.0) { $0 + ($1.carbs * $1.servings) }
    }
    
    private var totalFat: Double {
        selectedIngredients.reduce(0.0) { $0 + ($1.fat * $1.servings) }
    }
    
    private var isValid: Bool {
        !recipeName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedIngredients.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Details") {
                    TextField("Recipe Name (e.g. Morning Smoothie)", text: $recipeName)
                        .autocorrectionDisabled()
                }
                
                Section {
                    if selectedIngredients.isEmpty {
                        Text("No ingredients added yet. Tap below to add from your Saved Foods.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                    } else {
                        ForEach($selectedIngredients) { $ingredient in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(ingredient.foodName)
                                        .font(.headline)
                                    Spacer()
                                    Button(role: .destructive) {
                                        selectedIngredients.removeAll { $0.id == ingredient.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.subheadline)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                HStack {
                                    Text("Servings (\(ingredient.unit)):")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        TextField("1.0", value: $ingredient.servings, format: .number)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 50)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(Color.accentColor.opacity(0.1))
                                            .cornerRadius(6)
                                        
                                        Stepper("Adjust", value: $ingredient.servings, in: 0.1...10.0, step: 0.1)
                                            .labelsHidden()
                                    }
                                }
                                
                                // Ingredient nutrition preview
                                let cals = Int((Double(ingredient.calories) * ingredient.servings).rounded())
                                let prot = ingredient.protein * ingredient.servings
                                let carb = ingredient.carbs * ingredient.servings
                                let fatVal = ingredient.fat * ingredient.servings
                                Text("🔥 \(cals) cal  •  🔴 \(prot, specifier: "%.1f")g P  •  🔵 \(carb, specifier: "%.1f")g C  •  🟡 \(fatVal, specifier: "%.1f")g F")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Button {
                        showIngredientSelector = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Ingredient")
                        }
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Ingredients are selected from your existing Saved Foods. You can adjust the serving size of each ingredient individually.")
                }
                
                if !selectedIngredients.isEmpty {
                    Section("Total recipe nutrition") {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("Total Calories")
                                    .font(.headline)
                                Spacer()
                                Text("\(totalCalories)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            Divider()
                            
                            HStack(spacing: 20) {
                                MacroCircle(name: "Protein", value: totalProtein, color: .red)
                                MacroCircle(name: "Carbs", value: totalCarbs, color: .blue)
                                MacroCircle(name: "Fat", value: totalFat, color: .yellow)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(recipeToEdit == nil ? "Create Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showIngredientSelector) {
                IngredientSelectorView { food in
                    let stateItem = RecipeIngredientState(
                        foodName: food.foodName,
                        servings: 1.0,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        unit: food.unit
                    )
                    selectedIngredients.append(stateItem)
                }
            }
        }
    }
    
    private func saveRecipe() {
        if let recipe = recipeToEdit {
            recipe.name = recipeName
            recipe.ingredients = selectedIngredients.map {
                RecipeIngredient(
                    foodName: $0.foodName,
                    servings: $0.servings,
                    calories: $0.calories,
                    protein: $0.protein,
                    carbs: $0.carbs,
                    fat: $0.fat,
                    unit: $0.unit
                )
            }
        } else {
            let recipe = Recipe(name: recipeName)
            recipe.ingredients = selectedIngredients.map {
                RecipeIngredient(
                    foodName: $0.foodName,
                    servings: $0.servings,
                    calories: $0.calories,
                    protein: $0.protein,
                    carbs: $0.carbs,
                    fat: $0.fat,
                    unit: $0.unit
                )
            }
            modelContext.insert(recipe)
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

struct IngredientSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedFood.foodName) private var savedFoods: [SavedFood]
    
    var onSelect: (SavedFood) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if savedFoods.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Foods", systemImage: "book")
                    } description: {
                        Text("Add foods to your Saved Foods library first so you can select them as ingredients here.")
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(savedFoods) { food in
                        Button {
                            onSelect(food)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.foodName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("🔥 \(food.calories) cal  •  🔴 \(food.protein, specifier: "%.1f")g P  •  🔵 \(food.carbs, specifier: "%.1f")g C  •  🟡 \(food.fat, specifier: "%.1f")g F")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
