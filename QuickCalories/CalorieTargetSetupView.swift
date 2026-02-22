//
//  CalorieTargetSetupView.swift
//  QuickCalories
//
//  Created by John N on 2/18/26.
//

import SwiftUI

struct CalorieTargetSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dailyCalorieTarget: Int
    @Binding var proteinTarget: Double
    @Binding var carbsTarget: Double
    @Binding var fatTarget: Double
    
    let isOnboarding: Bool
    let onComplete: (() -> Void)?
    
    @State private var setupMode: SetupMode = .guided
    @State private var currentStep: Int = 1
    
    // Profile data
    @State private var goal: Goal = .maintain
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var heightCm: String = "" // For metric
    @State private var heightFeet: Int = 5 // For imperial
    @State private var heightInches: Int = 9 // For imperial
    @State private var gender: Gender = .notSpecified
    @State private var useMetric: Bool = false
    
    // Macro split
    @State private var macroSplit: MacroSplit = .balanced
    @State private var customProteinPercent: Double = 30
    @State private var customCarbsPercent: Double = 40
    @State private var customFatPercent: Double = 30
    
    // Manual calorie input
    @State private var manualCalories: Int = 2000
    
    // Calculated values
    @State private var calculatedCalories: Int = 0
    
    enum SetupMode {
        case guided
        case manual
    }
    
    var totalSteps: Int {
        setupMode == .guided ? 5 : 2
    }
    
    init(
        dailyCalorieTarget: Binding<Int>,
        proteinTarget: Binding<Double>,
        carbsTarget: Binding<Double>,
        fatTarget: Binding<Double>,
        isOnboarding: Bool = false,
        onComplete: (() -> Void)? = nil
    ) {
        self._dailyCalorieTarget = dailyCalorieTarget
        self._proteinTarget = proteinTarget
        self._carbsTarget = carbsTarget
        self._fatTarget = fatTarget
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isOnboarding {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(1...totalSteps, id: \.self) { step in
                            Capsule()
                                .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch setupMode {
                        case .guided:
                            guidedSetupContent
                        case .manual:
                            manualSetupContent
                        }
                    }
                    .padding()
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    if currentStep == 1 && setupMode == .guided {
                        Button {
                            setupMode = .manual
                            currentStep = 1
                        } label: {
                            Text("I'll set manually")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if currentStep > 1 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                Text("Back")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button {
                            handleContinue()
                        } label: {
                            Text(continueButtonText)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canContinue)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle(isOnboarding ? "Set Up Targets" : "Edit Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var guidedSetupContent: some View {
        switch currentStep {
        case 1:
            goalSelectionStep
        case 2:
            activityLevelStep
        case 3:
            profileInputStep
        case 4:
            calculatedResultsStep
        case 5:
            macroCustomizationStep
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var manualSetupContent: some View {
        switch currentStep {
        case 1:
            manualCalorieInputStep
        case 2:
            macroCustomizationStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Guided Steps
    
    private var goalSelectionStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What's your goal?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This helps us calculate your calorie target")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(Goal.allCases) { goalOption in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            goal = goalOption
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    } label: {
                        HStack {
                            Image(systemName: goalOption.icon)
                                .font(.title2)
                                .foregroundStyle(goal == goalOption ? .white : .blue)
                                .frame(width: 44)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goalOption.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(goal == goalOption ? .white : .primary)
                                
                                Text(goalOption.description)
                                    .font(.caption)
                                    .foregroundStyle(goal == goalOption ? .white.opacity(0.9) : .secondary)
                            }
                            
                            Spacer()
                            
                            if goal == goalOption {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(goal == goalOption ? Color.blue : Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var activityLevelStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("How active are you?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Consider your typical week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases) { level in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            activityLevel = level
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    } label: {
                        HStack {
                            Image(systemName: level.icon)
                                .font(.title3)
                                .foregroundStyle(activityLevel == level ? .white : .blue)
                                .frame(width: 44)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(activityLevel == level ? .white : .primary)
                                
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(activityLevel == level ? .white.opacity(0.9) : .secondary)
                            }
                            
                            Spacer()
                            
                            if activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(activityLevel == level ? Color.blue : Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var profileInputStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("About You")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help us calculate your personalized targets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("30", text: $age)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("years")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Weight")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Picker("Unit", selection: $useMetric) {
                            Text("lbs").tag(false)
                            Text("kg").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    
                    HStack {
                        TextField(useMetric ? "70" : "155", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        
                        Text(useMetric ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if useMetric {
                        // Metric: Single text field for cm
                        HStack {
                            TextField("175", text: $heightCm)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("cm")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // Imperial: Pickers for feet and inches
                        HStack(spacing: 12) {
                            // Feet picker
                            HStack {
                                Picker("Feet", selection: $heightFeet) {
                                    ForEach(3...7, id: \.self) { feet in
                                        Text("\(feet)").tag(feet)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                
                                Text("ft")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .cornerRadius(8)
                            
                            // Inches picker
                            HStack {
                                Picker("Inches", selection: $heightInches) {
                                    ForEach(0...11, id: \.self) { inches in
                                        Text("\(inches)").tag(inches)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                
                                Text("in")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases) { genderOption in
                            Text(genderOption.rawValue).tag(genderOption)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            Text("💡 This information stays on your device and is only used to calculate your recommended calorie target.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var calculatedResultsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Your Daily Targets")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Based on your profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 20) {
                // Large calorie number
                VStack(spacing: 4) {
                    Text("\(calculatedCalories)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    
                    Text("calories per day")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
                
                // Macro breakdown
                let macros = macroSplit.calculateMacros(totalCalories: calculatedCalories)
                
                VStack(spacing: 12) {
                    MacroRow(name: "Protein", amount: macros.protein, color: .red)
                    MacroRow(name: "Carbs", amount: macros.carbs, color: .blue)
                    MacroRow(name: "Fat", amount: macros.fat, color: .yellow)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                
                // Summary
                VStack(spacing: 8) {
                    Text("💡 This will help you \(goal.rawValue.lowercased()) with \(activityLevel.rawValue.lowercased())")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .onAppear {
            calculateTargets()
        }
    }
    
    private var macroCustomizationStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Customize Macros")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(setupMode == .guided ? "Adjust your macro split" : "Set your macro distribution")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Calorie display
            VStack(spacing: 4) {
                Text("\(setupMode == .guided ? calculatedCalories : manualCalories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                
                Text("calories per day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            
            // Macro split presets
            VStack(alignment: .leading, spacing: 12) {
                Text("Macro Split")
                    .font(.headline)
                
                ForEach(MacroSplit.allCases) { split in
                    Button {
                        withAnimation {
                            macroSplit = split
                            if split != .custom {
                                let percentages = split.percentages
                                customProteinPercent = percentages.protein * 100
                                customCarbsPercent = percentages.carbs * 100
                                customFatPercent = percentages.fat * 100
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(split.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(macroSplit == split ? .white : .primary)
                                
                                if split != .custom {
                                    Text(split.description)
                                        .font(.caption)
                                        .foregroundStyle(macroSplit == split ? .white.opacity(0.9) : .secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if macroSplit == split {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(macroSplit == split ? Color.blue : Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Custom sliders (if custom selected)
            if macroSplit == .custom {
                VStack(spacing: 16) {
                    MacroPercentageSlider(
                        name: "Protein",
                        percentage: $customProteinPercent,
                        color: .red
                    )
                    
                    MacroPercentageSlider(
                        name: "Carbs",
                        percentage: $customCarbsPercent,
                        color: .blue
                    )
                    
                    MacroPercentageSlider(
                        name: "Fat",
                        percentage: $customFatPercent,
                        color: .yellow
                    )
                    
                    let total = customProteinPercent + customCarbsPercent + customFatPercent
                    if abs(total - 100) > 0.5 {
                        Text("⚠️ Percentages should total 100%")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Preview
            let calories = setupMode == .guided ? calculatedCalories : manualCalories
            let macros = calculateFinalMacros(calories: calories)
            
            VStack(spacing: 12) {
                Text("Daily Targets")
                    .font(.headline)
                
                MacroRow(name: "Protein", amount: macros.protein, color: .red)
                MacroRow(name: "Carbs", amount: macros.carbs, color: .blue)
                MacroRow(name: "Fat", amount: macros.fat, color: .yellow)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var manualCalorieInputStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Set Calorie Target")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose your daily calorie goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 20) {
                // Large input
                VStack(spacing: 8) {
                    TextField("2000", value: $manualCalories, format: .number)
                        .keyboardType(.numberPad)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.center)
                    
                    Text("calories per day")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { Double(manualCalories) },
                        set: { manualCalories = Int($0) }
                    ), in: 1200...4000, step: 50)
                    
                    HStack {
                        Text("1,200")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("4,000")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                
                // Common presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Targets")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach([1500, 2000, 2500, 3000], id: \.self) { preset in
                            Button {
                                withAnimation {
                                    manualCalories = preset
                                }
                            } label: {
                                Text("\(preset)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(manualCalories == preset ? Color.blue : Color(uiColor: .secondarySystemBackground))
                                    .foregroundStyle(manualCalories == preset ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            if manualCalories < 1500 {
                Text("⚠️ Very low calorie diets should be supervised by a healthcare professional")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct MacroRow: View {
        let name: String
        let amount: Double
        let color: Color
        
        var body: some View {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text("\(Int(amount))g")
                    .font(.headline)
                    .foregroundStyle(color)
            }
        }
    }
    
    private struct MacroPercentageSlider: View {
        let name: String
        @Binding var percentage: Double
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                        
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(percentage))%")
                        .font(.headline)
                        .foregroundStyle(color)
                }
                
                Slider(value: $percentage, in: 10...60, step: 5)
                    .tint(color)
            }
        }
    }
    
    // MARK: - Logic
    
    private var canContinue: Bool {
        switch setupMode {
        case .guided:
            switch currentStep {
            case 1, 2, 4: return true
            case 3:
                // Validate profile input
                if age.isEmpty || weight.isEmpty { return false }
                if useMetric {
                    return !heightCm.isEmpty
                } else {
                    return true // Pickers always have a value
                }
            case 5: return macroSplit != .custom || abs(customProteinPercent + customCarbsPercent + customFatPercent - 100) < 0.5
            default: return false
            }
        case .manual:
            switch currentStep {
            case 1: return manualCalories >= 1200 && manualCalories <= 4000
            case 2: return macroSplit != .custom || abs(customProteinPercent + customCarbsPercent + customFatPercent - 100) < 0.5
            default: return false
            }
        }
    }
    
    private var continueButtonText: String {
        let isLastStep = (setupMode == .guided && currentStep == 5) || (setupMode == .manual && currentStep == 2)
        return isLastStep ? "Save Targets" : "Continue"
    }
    
    private func handleContinue() {
        let isLastStep = (setupMode == .guided && currentStep == totalSteps) || (setupMode == .manual && currentStep == 2)
        
        if isLastStep {
            saveTargets()
            if let onComplete = onComplete {
                onComplete()
            } else {
                dismiss()
            }
        } else {
            withAnimation {
                currentStep += 1
            }
            
            // Calculate targets when reaching step 4
            if setupMode == .guided && currentStep == 4 {
                calculateTargets()
            }
        }
    }
    
    private func calculateTargets() {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight) else {
            calculatedCalories = 2000
            return
        }
        
        // Get height in cm
        let heightInCm: Double
        if useMetric {
            guard let heightCmDouble = Double(heightCm) else {
                calculatedCalories = 2000
                return
            }
            heightInCm = heightCmDouble
        } else {
            // Convert feet and inches to cm
            let totalInches = Double(heightFeet * 12 + heightInches)
            heightInCm = totalInches.inchesToCm
        }
        
        // Convert weight to kg if needed
        let weightKg = useMetric ? weightDouble : weightDouble.lbsToKg
        
        calculatedCalories = CalorieCalculator.calculateDailyTarget(
            weight: weightKg,
            height: heightInCm,
            age: ageInt,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )
    }
    
    private func calculateFinalMacros(calories: Int) -> (protein: Double, carbs: Double, fat: Double) {
        if macroSplit == .custom {
            let proteinCals = Double(calories) * (customProteinPercent / 100.0)
            let carbsCals = Double(calories) * (customCarbsPercent / 100.0)
            let fatCals = Double(calories) * (customFatPercent / 100.0)
            
            return (
                protein: proteinCals / 4.0,
                carbs: carbsCals / 4.0,
                fat: fatCals / 9.0
            )
        } else {
            return macroSplit.calculateMacros(totalCalories: calories)
        }
    }
    
    private func saveTargets() {
        let settings = SettingsManager.shared
        
        // Save calorie target
        if setupMode == .guided {
            dailyCalorieTarget = calculatedCalories
            settings.dailyCalorieTarget = calculatedCalories
            
            // Save profile data
            if let ageInt = Int(age), let weightDouble = Double(weight) {
                settings.userAge = ageInt
                let weightKg = useMetric ? weightDouble : weightDouble.lbsToKg
                
                // Get height in cm
                let heightInCm: Double
                if useMetric {
                    heightInCm = Double(heightCm) ?? 170.0
                } else {
                    let totalInches = Double(heightFeet * 12 + heightInches)
                    heightInCm = totalInches.inchesToCm
                }
                
                settings.userWeight = weightKg
                settings.userHeight = heightInCm
                settings.userGender = gender.rawValue
                settings.activityLevel = activityLevel.rawValue
                settings.goalType = goal.rawValue
                settings.useMetricSystem = useMetric
            }
            
            // Calculate and save macros
            let macros = calculateFinalMacros(calories: calculatedCalories)
            proteinTarget = macros.protein
            carbsTarget = macros.carbs
            fatTarget = macros.fat
            settings.proteinTarget = macros.protein
            settings.carbsTarget = macros.carbs
            settings.fatTarget = macros.fat
        } else {
            dailyCalorieTarget = manualCalories
            settings.dailyCalorieTarget = manualCalories
            
            let macros = calculateFinalMacros(calories: manualCalories)
            proteinTarget = macros.protein
            carbsTarget = macros.carbs
            fatTarget = macros.fat
            settings.proteinTarget = macros.protein
            settings.carbsTarget = macros.carbs
            settings.fatTarget = macros.fat
        }
        
        // Save macro split preference
        settings.macroSplitType = macroSplit.rawValue
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    CalorieTargetSetupView(
        dailyCalorieTarget: .constant(2000),
        proteinTarget: .constant(150),
        carbsTarget: .constant(200),
        fatTarget: .constant(67),
        isOnboarding: true
    )
}
