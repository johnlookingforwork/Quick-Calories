//
//  OnboardingView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var calorieGoal = 2000
    @State private var macroSliderPosition: Double = 0.5
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if currentStep == 0 {
                CalorieGoalView(calorieGoal: $calorieGoal) {
                    withAnimation {
                        currentStep = 1
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                MacroDistributionView(
                    calorieGoal: calorieGoal,
                    sliderPosition: $macroSliderPosition
                ) {
                    completeOnboarding()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut, value: currentStep)
    }
    
    private func completeOnboarding() {
        let settings = SettingsManager.shared
        settings.dailyCalorieTarget = calorieGoal
        
        let (protein, carbs, fat) = calculateMacros(calories: calorieGoal, sliderPosition: macroSliderPosition)
        settings.proteinTarget = protein
        settings.carbsTarget = carbs
        settings.fatTarget = fat
        settings.hasCompletedOnboarding = true
        
        dismiss()
    }
    
    private func calculateMacros(calories: Int, sliderPosition: Double) -> (protein: Double, carbs: Double, fat: Double) {
        let fatCalories = Double(calories) * 0.3
        let fat = fatCalories / 9.0
        
        let remainingCalories = Double(calories) - fatCalories
        let proteinPercentage = 0.4 - (sliderPosition * 0.2)
        let carbPercentage = 1.0 - proteinPercentage - 0.3
        
        let proteinCalories = remainingCalories * proteinPercentage
        let carbCalories = remainingCalories * carbPercentage
        
        let protein = proteinCalories / 4.0
        let carbs = carbCalories / 4.0
        
        return (protein.rounded(), carbs.rounded(), fat.rounded())
    }
}

struct CalorieGoalView: View {
    @Binding var calorieGoal: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Daily Calorie Goal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("How many calories do you want to eat per day?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("2000", text: Binding(
                get: { String(calorieGoal) },
                set: { calorieGoal = Int($0) ?? 2000 }
            ))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
            
            Text("You can change this anytime in Settings")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
}

struct MacroDistributionView: View {
    let calorieGoal: Int
    @Binding var sliderPosition: Double
    let onContinue: () -> Void
    
    private var macros: (protein: Double, carbs: Double, fat: Double) {
        calculateMacros()
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Macro Distribution")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Adjust your protein and carb balance")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 24) {
                HStack {
                    Text("High Protein")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("High Carb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $sliderPosition, in: 0...1)
                    .tint(.accentColor)
                
                VStack(spacing: 16) {
                    MacroRow(name: "Protein", value: macros.protein, color: .red)
                    MacroRow(name: "Carbs", value: macros.carbs, color: .blue)
                    MacroRow(name: "Fat", value: macros.fat, color: .yellow)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
    
    private func calculateMacros() -> (protein: Double, carbs: Double, fat: Double) {
        let fatCalories = Double(calorieGoal) * 0.3
        let fat = fatCalories / 9.0
        
        let remainingCalories = Double(calorieGoal) - fatCalories
        let proteinPercentage = 0.4 - (sliderPosition * 0.2)
        let carbPercentage = 1.0 - proteinPercentage - 0.3
        
        let proteinCalories = remainingCalories * proteinPercentage
        let carbCalories = remainingCalories * carbPercentage
        
        let protein = proteinCalories / 4.0
        let carbs = carbCalories / 4.0
        
        return (protein.rounded(), carbs.rounded(), fat.rounded())
    }
}

struct MacroRow: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(name)
                .font(.body)
            Spacer()
            Text("\(Int(value))g")
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    OnboardingView()
}
