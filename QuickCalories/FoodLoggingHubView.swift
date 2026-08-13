//
//  FoodLoggingHubView.swift
//  QuickCalories
//
//  Created by John N on 8/13/26.
//

import SwiftUI
import SwiftData

struct FoodLoggingHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    
    // Database Queries
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @Query(sort: \SavedFood.orderIndex) private var savedFoods: [SavedFood]
    @Query(sort: \Recipe.orderIndex) private var recipes: [Recipe]
    
    // View States
    @State private var searchText = ""
    @State private var activeTab = 0 // 0 = Recents, 1 = Saved Foods, 2 = Recipes
    
    // Presentation States
    @State private var itemToLog: LoggableItem? = nil
    @State private var foodToEdit: SavedFood? = nil
    @State private var foodToShare: SavedFood? = nil
    @State private var recipeToEdit: Recipe? = nil
    @State private var editMode: EditMode = .inactive
    @State private var showAILog = false
    @State private var showManualAdd = false
    @State private var showRecipeBuilder = false
    @State private var showAddSavedFood = false
    
    // QR Scanner States
    @State private var showScanner = false
    @State private var showScanError = false
    @State private var scanErrorMessage = ""
    @State private var importingFood: SavedFood? = nil
    

    
    // Compute unique recent entries (last 25 unique items logged)
    private var recentUniqueFoods: [LoggableItem] {
        var seen = Set<String>()
        var result: [LoggableItem] = []
        
        for entry in allEntries {
            let key = entry.foodName.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                
                // Calculate single serving base macros
                let s = entry.servings > 0 ? entry.servings : 1.0
                let baseCals = Int((Double(entry.calories) / s).rounded())
                let baseProt = entry.protein / s
                let baseCarbs = entry.carbs / s
                let baseFat = entry.fat / s
                
                result.append(
                    LoggableItem(
                        name: entry.foodName,
                        calories: baseCals,
                        protein: baseProt,
                        carbs: baseCarbs,
                        fat: baseFat,
                        recipeDescription: entry.recipeDescription
                    )
                )
                if result.count >= 25 { break }
            }
        }
        return result
    }
    
    // Filtered lists based on search query
    private var filteredRecents: [LoggableItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return recentUniqueFoods
        }
        return recentUniqueFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredSavedFoods: [SavedFood] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return savedFoods
        }
        return savedFoods.filter { $0.foodName.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredRecipes: [Recipe] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Smart Search and Scanner Header
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search foods, recipes, or describe...", text: $searchText)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // QR scanner button
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                
                // Tabs Picker
                Picker("Tabs", selection: $activeTab) {
                    Text("Recents").tag(0)
                    Text("Saved Foods").tag(1)
                    Text("Recipes").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                // List content
                List {
                    // Inline AI Search Suggestion
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Section {
                            Button {
                                showAILog = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ask AI to log \"\(searchText)\"")
                                            .font(.headline)
                                            .foregroundStyle(.purple)
                                        Text("Gemini will estimate macros automatically")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    if activeTab == 0 {
                        recentsSection
                    } else if activeTab == 1 {
                        savedFoodsSection
                    } else {
                        recipesSection
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, $editMode)
                
                // Bottom Bar Actions
                HStack(spacing: 16) {
                    Button {
                        showManualAdd = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Manual Add")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        showAILog = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Log with AI")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Log Food")
                            .font(.headline)
                        Text("Swipe right on items to edit or share")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if activeTab > 0 {
                        Button(editMode == .active ? "Done" : "Reorder") {
                            withAnimation {
                                editMode = (editMode == .active) ? .inactive : .active
                            }
                        }
                    }
                }
            }
            // Bottom confirmation sheet for log servings
            .sheet(item: $itemToLog) { loggable in
                ServingsPickerCard(
                    foodName: loggable.name,
                    calories: loggable.calories,
                    protein: loggable.protein,
                    carbs: loggable.carbs,
                    fat: loggable.fat,
                    recipeDescription: loggable.recipeDescription
                ) { servings in
                    logItemToFeed(item: loggable, servings: servings)
                }
            }
            .sheet(item: $foodToEdit) { food in
                EditSavedFoodView(food: food)
            }
            .sheet(item: $foodToShare) { food in
                ShareFoodQRView(food: food)
            }
            .sheet(item: $recipeToEdit) { recipe in
                RecipeBuilderView(recipeToEdit: recipe)
            }
            // Sheet triggers
            .sheet(isPresented: $showAILog) {
                AILogView(date: date, initialTextInput: searchText, initialInputMode: searchText.isEmpty ? nil : .text)
            }
            .sheet(isPresented: $showManualAdd) {
                ManualAddView(date: date)
            }
            .sheet(isPresented: $showRecipeBuilder) {
                RecipeBuilderView()
            }
            .sheet(isPresented: $showAddSavedFood) {
                AddSavedFoodView()
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { scannedPayload in
                    showScanner = false
                    handleScanSuccess(payload: scannedPayload)
                } onScanFailure: { error in
                    showScanner = false
                    scanErrorMessage = error
                    showScanError = true
                }
            }
            .sheet(item: $importingFood) { food in
                ImportSavedFoodView(food: food) {
                    // Success callback
                }
            }
            .alert("Scanning Error", isPresented: $showScanError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scanErrorMessage)
            }
        }
    }
    
    // --- Sub-sections for Tabs ---
    
    @ViewBuilder
    private var recentsSection: some View {
        if filteredRecents.isEmpty {
            Section {
                Text(searchText.isEmpty ? "No recent food entries found." : "No matching recent foods.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } else {
            Section("Recently logged") {
                ForEach(filteredRecents) { item in
                    Button {
                        itemToLog = item
                    } label: {
                        FoodHubCard(
                            name: item.name,
                            calories: item.calories,
                            protein: item.protein,
                            carbs: item.carbs,
                            fat: item.fat,
                            recipeDescription: item.recipeDescription
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private var savedFoodsSection: some View {
        if filteredSavedFoods.isEmpty {
            Section {
                Button {
                    showAddSavedFood = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Food")
                    }
                }
                
                Text(searchText.isEmpty ? "No saved food templates found." : "No matching saved foods.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } else {
            Section("Your Foods") {
                Button {
                    showAddSavedFood = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Food")
                    }
                }
                
                ForEach(filteredSavedFoods) { food in
                    Button {
                        itemToLog = LoggableItem(
                            name: food.foodName,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fat: food.fat
                        )
                    } label: {
                        FoodHubCard(
                            name: food.foodName,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fat: food.fat,
                            servingInfo: "\(String(format: "%.1f", food.servingSize)) \(food.unit)"
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(food)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            foodToEdit = food
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        Button {
                            foodToShare = food
                        } label: {
                            Label("Share", systemImage: "qrcode")
                        }
                        .tint(.purple)
                    }
                }
                .onMove(perform: moveSavedFoods)
            }
        }
    }
    
    @ViewBuilder
    private var recipesSection: some View {
        if filteredRecipes.isEmpty {
            Section {
                Button {
                    showRecipeBuilder = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Recipe")
                    }
                }
                
                Text(searchText.isEmpty ? "No recipes saved yet." : "No matching recipes.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } else {
            Section("Your Recipes") {
                Button {
                    showRecipeBuilder = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Recipe")
                    }
                }
                
                ForEach(filteredRecipes) { recipe in
                    Button {
                        itemToLog = LoggableItem(
                            name: recipe.name,
                            calories: recipe.totalCalories,
                            protein: recipe.totalProtein,
                            carbs: recipe.totalCarbs,
                            fat: recipe.totalFat,
                            recipeDescription: recipe.ingredientListSummary,
                            isRecipe: true
                        )
                    } label: {
                        FoodHubCard(
                            name: recipe.name,
                            calories: recipe.totalCalories,
                            protein: recipe.totalProtein,
                            carbs: recipe.totalCarbs,
                            fat: recipe.totalFat,
                            recipeDescription: recipe.ingredientListSummary
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            recipeToEdit = recipe
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        Button {
                            // Temporary conversion of Recipe to SavedFood for QR code presentation
                            let tempFood = SavedFood(
                                foodName: recipe.name,
                                servingSize: 1.0,
                                unit: "serving",
                                calories: recipe.totalCalories,
                                protein: recipe.totalProtein,
                                carbs: recipe.totalCarbs,
                                fat: recipe.totalFat
                            )
                            foodToShare = tempFood
                        } label: {
                            Label("Share", systemImage: "qrcode")
                        }
                        .tint(.purple)
                    }
                }
                .onMove(perform: moveRecipes)
            }
        }
    }
    
    // --- Logging Helper ---
    
    private func logItemToFeed(item: LoggableItem, servings: Double) {
        let smartTimestamp = adjustTimestampForDateContext(date)
        
        let calories = Int((Double(item.calories) * servings).rounded())
        let protein = item.protein * servings
        let carbs = item.carbs * servings
        let fat = item.fat * servings
        
        let entry = FoodEntry(
            foodName: item.name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servings: servings,
            timestamp: smartTimestamp,
            recipeDescription: item.recipeDescription
        )
        
        modelContext.insert(entry)
        DailyTargetLog.ensureTargetLog(for: smartTimestamp, modelContext: modelContext)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
    
    private func adjustTimestampForDateContext(_ date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return now
        }
        
        if date > now {
            return calendar.startOfDay(for: date)
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        return calendar.date(from: components) ?? date
    }
    
    private func moveSavedFoods(from source: IndexSet, to destination: Int) {
        var revisedItems = filteredSavedFoods
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for index in 0..<revisedItems.count {
            revisedItems[index].orderIndex = index
        }
        
        try? modelContext.save()
    }
    
    private func moveRecipes(from source: IndexSet, to destination: Int) {
        var revisedItems = filteredRecipes
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for index in 0..<revisedItems.count {
            revisedItems[index].orderIndex = index
        }
        
        try? modelContext.save()
    }
    
    // --- QR Scan Helper ---
    
    private func handleScanSuccess(payload: String) {
        guard let data = payload.data(using: .utf8) else {
            scanErrorMessage = "The scanned code is empty or invalid."
            showScanError = true
            return
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                scanErrorMessage = "Failed to parse the QR code. Please check that you are scanning a QuickCalories code."
                showScanError = true
                return
            }
            
            guard let type = json["type"] as? String, type == "quickcalories_food" else {
                scanErrorMessage = "This QR code does not contain a QuickCalories food item."
                showScanError = true
                return
            }
            
            guard let name = json["name"] as? String,
                  let servingSize = json["servingSize"] as? Double,
                  let unit = json["unit"] as? String,
                  let calories = json["calories"] as? Int,
                  let protein = json["protein"] as? Double,
                  let carbs = json["carbs"] as? Double,
                  let fat = json["fat"] as? Double else {
                scanErrorMessage = "The shared food data is incomplete or corrupted."
                showScanError = true
                return
            }
            
            let minIndex = SavedFood.nextOrderIndex(modelContext: modelContext)
            let food = SavedFood(
                foodName: name,
                servingSize: servingSize,
                unit: unit,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                orderIndex: minIndex
            )
            
            DispatchQueue.main.async {
                self.importingFood = food
            }
            
        } catch {
            scanErrorMessage = "Could not decode QR code data: \(error.localizedDescription)"
            showScanError = true
        }
    }
}

// Type wrapper to unify items for servings selection
struct LoggableItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int // Per-serving
    let protein: Double
    let carbs: Double
    let fat: Double
    var recipeDescription: String? = nil
    var isRecipe: Bool = false
}

struct FoodHubCard: View {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    var servingInfo: String? = nil
    var recipeDescription: String? = nil
    var timestamp: Date? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                // Calories with flame icon
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(calories) cal")
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
                        Text("\(Int(protein))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Carbs
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                        Text("\(Int(carbs))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Fat
                    HStack(spacing: 3) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.yellow)
                        Text("\(Int(fat))g")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let desc = recipeDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                        .multilineTextAlignment(.leading)
                }
                
                if let servingInfo = servingInfo, !servingInfo.isEmpty {
                    Text(servingInfo)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                if let timestamp = timestamp {
                    Text(timestamp, style: .time)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // makes entire card tappable
    }
}
