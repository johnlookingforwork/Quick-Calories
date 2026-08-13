//
//  ServingsPickerCard.swift
//  QuickCalories
//
//  Created by John N on 8/13/26.
//

import SwiftUI

struct ServingsPickerCard: View {
    @Environment(\.dismiss) private var dismiss
    
    let foodName: String
    let calories: Int // Per-serving values
    let protein: Double
    let carbs: Double
    let fat: Double
    var recipeDescription: String? = nil
    
    @State private var servings = 1.0
    
    var onLog: (Double) -> Void
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        (
            calories: Int((Double(calories) * servings).rounded()),
            protein: protein * servings,
            carbs: carbs * servings,
            fat: fat * servings
        )
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 6) {
                Text(foodName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.horizontal)
                
                if let desc = recipeDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            
            // Running nutrition summary card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Total Calories")
                        .font(.headline)
                    Spacer()
                    Text("\(calculatedValues.calories)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundStyle(.orange)
                    Text("cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    MacroCircle(name: "Protein", value: calculatedValues.protein, color: .red)
                    MacroCircle(name: "Carbs", value: calculatedValues.carbs, color: .blue)
                    MacroCircle(name: "Fat", value: calculatedValues.fat, color: .yellow)
                }
                .padding(.bottom, 8)
            }
            .padding(.vertical)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(16)
            
            // Servings controls
            VStack(spacing: 12) {
                HStack {
                    Text("How many servings?")
                        .font(.headline)
                    Spacer()
                    
                    HStack(spacing: 8) {
                        TextField("1.0", value: $servings, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
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
                    }
                }
                
                HStack {
                    Spacer()
                    Stepper("Adjust servings", value: $servings, in: 0.1...20, step: 0.1)
                        .labelsHidden()
                }
            }
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(12)
            
            // Log button
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                onLog(servings)
                dismiss()
            } label: {
                Text("Log Food")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
