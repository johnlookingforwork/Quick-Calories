//
//  SavedFoodsView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct SavedFoodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedFood.createdAt, order: .reverse) private var savedFoods: [SavedFood]
    @State private var showAddFood = false
    @State private var foodToLog: SavedFood?
    @State private var foodToEdit: SavedFood?
    @State private var searchText = ""
    
    let logDate: Date?
    
    init(logDate: Date? = nil) {
        self.logDate = logDate
    }
    
    private var filteredFoods: [SavedFood] {
        if searchText.isEmpty {
            return savedFoods
        }
        return savedFoods.filter { $0.foodName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if savedFoods.isEmpty {
                ContentUnavailableView {
                    Label("No Saved Foods", systemImage: "book.closed")
                } description: {
                    Text("Create custom foods you eat regularly for quick logging without AI.\n\nTap any saved food to log it instantly!")
                        .multilineTextAlignment(.center)
                } actions: {
                    Button("Add First Food") {
                        showAddFood = true
                    }
                }
            } else {
                List {
                    ForEach(filteredFoods) { food in
                        SavedFoodRow(food: food)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                foodToLog = food
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFood(food)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    foodToEdit = food
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search saved foods")
            }
        }
        .navigationTitle("Saved Foods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Saved Foods")
                        .font(.headline)
                    if !savedFoods.isEmpty {
                        Text("Tap to log • Swipe right to edit")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddSavedFoodView()
        }
        .sheet(item: $foodToLog) { food in
            LogSavedFoodView(food: food, date: logDate ?? Date())
        }
        .sheet(item: $foodToEdit) { food in
            EditSavedFoodView(food: food)
        }
    }
    
    private func deleteFood(_ food: SavedFood) {
        withAnimation {
            modelContext.delete(food)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct SavedFoodRow: View {
    let food: SavedFood
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(food.foodName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(food.servingSize, specifier: "%.1f") \(food.unit) • \(food.calories) cal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Text("P: \(Int(food.protein))g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("C: \(Int(food.carbs))g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("F: \(Int(food.fat))g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Visual indicator that this is tappable to log
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text("Tap to log")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSavedFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var foodName = ""
    @State private var servingSize = ""
    @State private var unit = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    private var isValid: Bool {
        !foodName.isEmpty &&
        Double(servingSize) != nil &&
        !unit.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fat) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                    
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit", text: $unit)
                            .frame(width: 80)
                    }
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
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Saved Food")
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
        guard let servingSizeValue = Double(servingSize),
              let caloriesValue = Int(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            return
        }
        
        let food = SavedFood(
            foodName: foodName,
            servingSize: servingSizeValue,
            unit: unit,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue
        )
        
        modelContext.insert(food)
        dismiss()
    }
}

struct EditSavedFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let food: SavedFood
    
    @State private var foodName: String
    @State private var servingSize: String
    @State private var unit: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    
    init(food: SavedFood) {
        self.food = food
        _foodName = State(initialValue: food.foodName)
        _servingSize = State(initialValue: String(food.servingSize))
        _unit = State(initialValue: food.unit)
        _calories = State(initialValue: String(food.calories))
        _protein = State(initialValue: String(food.protein))
        _carbs = State(initialValue: String(food.carbs))
        _fat = State(initialValue: String(food.fat))
    }
    
    private var isValid: Bool {
        !foodName.isEmpty &&
        Double(servingSize) != nil &&
        !unit.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fat) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                    
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit", text: $unit)
                            .frame(width: 80)
                    }
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
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Saved Food")
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let servingSizeValue = Double(servingSize),
              let caloriesValue = Int(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            return
        }
        
        food.foodName = foodName
        food.servingSize = servingSizeValue
        food.unit = unit
        food.calories = caloriesValue
        food.protein = proteinValue
        food.carbs = carbsValue
        food.fat = fatValue
        
        dismiss()
    }
}

struct LogSavedFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let food: SavedFood
    let date: Date
    
    @State private var servings = 1.0
    @FocusState private var isServingsFocused: Bool
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        (
            calories: Int(Double(food.calories) * servings),
            protein: food.protein * servings,
            carbs: food.carbs * servings,
            fat: food.fat * servings
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.foodName)
                            .font(.headline)
                        Text("\(food.servingSize, specifier: "%.1f") \(food.unit) per serving")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    HStack {
                        Text("How many servings?")
                        Spacer()
                        
                        // Interactive servings control
                        HStack(spacing: 8) {
                            TextField("1.0", value: $servings, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .focused($isServingsFocused)
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
                        .onTapGesture {
                            isServingsFocused = true
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Stepper("Adjust servings", value: $servings, in: 0.1...20, step: 0.5)
                            .labelsHidden()
                    }
                } header: {
                    Text("Servings")
                } footer: {
                    Text("Tap the number to type, or use +/- buttons to adjust")
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
            }
            .navigationTitle("Log Food")
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
        }
    }
    
    private func logFood() {
        let entry = FoodEntry(
            foodName: food.foodName,
            calories: calculatedValues.calories,
            protein: calculatedValues.protein,
            carbs: calculatedValues.carbs,
            fat: calculatedValues.fat,
            servings: servings,
            timestamp: date  // Use provided date
        )
        
        modelContext.insert(entry)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SavedFoodsView()
            .modelContainer(for: SavedFood.self, inMemory: true)
    }
}
