//
//  ImportSavedFoodView.swift
//  QuickCalories
//
//  Created by John N on 8/8/26.
//

import SwiftUI
import SwiftData

struct ImportSavedFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let food: SavedFood
    var date: Date? = nil
    let onImportComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Large styled status icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Import Food Item?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You scanned a food shared by another user. Choose an action below.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Food details card
                VStack(spacing: 16) {
                    Text(food.foodName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(food.calories) cal • \(food.servingSize, specifier: "%.1f") \(food.unit)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 20) {
                        MacroImportBadge(name: "Protein", amount: food.protein, color: .red)
                        MacroImportBadge(name: "Carbs", amount: food.carbs, color: .blue)
                        MacroImportBadge(name: "Fat", amount: food.fat, color: .yellow)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        logImmediately()
                    } label: {
                        Text("Log Food Immediately")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        importFood()
                    } label: {
                        Text("Add to Saved Foods Library")
                            .font(.headline)
                            .foregroundColor(Color.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func logImmediately() {
        let dateContext = date ?? Date()
        let smartTimestamp = adjustTimestampForDateContext(dateContext)
        
        let entry = FoodEntry(
            foodName: food.foodName,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            servings: 1.0,
            timestamp: smartTimestamp
        )
        
        modelContext.insert(entry)
        DailyTargetLog.ensureTargetLog(for: smartTimestamp, modelContext: modelContext)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        onImportComplete()
        dismiss()
    }
    
    private func importFood() {
        // Insert into SwiftData context
        modelContext.insert(food)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        onImportComplete()
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
}

struct MacroImportBadge: View {
    let name: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(amount))g")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
