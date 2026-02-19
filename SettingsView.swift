//
//  SettingsView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var calorieTarget = 2000
    @State private var proteinTarget = 150.0
    @State private var carbsTarget = 200.0
    @State private var fatTarget = 67.0
    @State private var sliderPosition: Double = 0.5
    @State private var useSlider = false
    @State private var apiKey = ""
    @State private var showAPIKeyInfo = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case calories, protein, carbs, fat, apiKey
    }
    
    // Calculate macros from slider position (same as onboarding)
    private var calculatedMacros: (protein: Double, carbs: Double, fat: Double) {
        let fatCalories = Double(calorieTarget) * 0.3
        let fat = fatCalories / 9.0
        
        let remainingCalories = Double(calorieTarget) - fatCalories
        let proteinPercentage = 0.4 - (sliderPosition * 0.2) // 0.4 to 0.2
        let carbPercentage = 1.0 - proteinPercentage - 0.3
        
        let proteinCalories = remainingCalories * proteinPercentage
        let carbCalories = remainingCalories * carbPercentage
        
        let protein = proteinCalories / 4.0
        let carbs = carbCalories / 4.0
        
        return (protein.rounded(), carbs.rounded(), fat.rounded())
    }
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Text("Daily Calorie Goal")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    TextField("2000", value: $calorieTarget, format: .number)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .calories)
                        .onChange(of: calorieTarget) { _, newValue in
                            SettingsManager.shared.dailyCalorieTarget = newValue
                        }
                    
                    Text("calories per day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            }
            
            Section {
                VStack(spacing: 20) {
                    // Toggle between slider and manual
                    Picker("Mode", selection: $useSlider) {
                        Text("Manual").tag(false)
                        Text("Slider").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: useSlider) { _, newValue in
                        if newValue {
                            // Switching to slider mode - update to calculated values
                            applyCalculatedMacros()
                        }
                    }
                    
                    if useSlider {
                        // Slider mode (like onboarding)
                        VStack(spacing: 16) {
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
                                .onChange(of: sliderPosition) { _, _ in
                                    applyCalculatedMacros()
                                }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Macro rows - editable in manual mode, display-only in slider mode
                    VStack(spacing: 16) {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text("Protein")
                                .font(.body)
                            Spacer()
                            if useSlider {
                                Text("\(Int(proteinTarget))")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            } else {
                                TextField("150", value: $proteinTarget, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .protein)
                                    .onChange(of: proteinTarget) { _, newValue in
                                        SettingsManager.shared.proteinTarget = newValue
                                    }
                            }
                            Text("g")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 12, height: 12)
                            Text("Carbs")
                                .font(.body)
                            Spacer()
                            if useSlider {
                                Text("\(Int(carbsTarget))")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            } else {
                                TextField("200", value: $carbsTarget, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .carbs)
                                    .onChange(of: carbsTarget) { _, newValue in
                                        SettingsManager.shared.carbsTarget = newValue
                                    }
                            }
                            Text("g")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 12, height: 12)
                            Text("Fat")
                                .font(.body)
                            Spacer()
                            if useSlider {
                                Text("\(Int(fatTarget))")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            } else {
                                TextField("67", value: $fatTarget, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .fat)
                                    .onChange(of: fatTarget) { _, newValue in
                                        SettingsManager.shared.fatTarget = newValue
                                    }
                            }
                            Text("g")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            } header: {
                Text("Macro Targets")
            } footer: {
                if useSlider {
                    Text("Slide to adjust your protein and carb balance. Fat is fixed at 30% of calories.")
                } else {
                    Text("Manually set your macro targets or switch to Slider mode for quick adjustment.")
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                        .frame(width: 32)
                    
                    Text("OpenAI API Key")
                        .font(.body)
                    
                    Spacer()
                    
                    Button {
                        showAPIKeyInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                    
                    SecureField("Optional - sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .apiKey)
                        .onChange(of: apiKey) { _, newValue in
                            SettingsManager.shared.openAIApiKey = newValue.isEmpty ? nil : newValue
                        }
                }
                .padding(.vertical, 4)
                
                if !apiKey.isEmpty {
                    Button(role: .destructive) {
                        apiKey = ""
                        SettingsManager.shared.openAIApiKey = nil
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 32)
                            Text("Clear API Key")
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("AI Configuration")
            } footer: {
                Text("Supply your own OpenAI API key to bypass the 1 request per day limit, or subscribe for unlimited requests.")
            }
            
            Section {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 32)
                    
                    Text("Daily AI Requests")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(SettingsManager.shared.dailyAIRequestCount) / 1")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
                
                if let lastReset = SettingsManager.shared.lastRequestResetDate {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 32)
                        
                        Text("Resets at Midnight")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(lastReset, style: .date)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Usage")
            }
            
            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 32)
                    
                    Text("Version")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("1.0")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .frame(width: 32)
                        
                        Text("Privacy Policy")
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                        
                        Text("Terms of Service")
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("About")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $showAPIKeyInfo) {
            APIKeyInfoView()
        }
        .onAppear {
            // Load values from SettingsManager on appear
            let settings = SettingsManager.shared
            calorieTarget = settings.dailyCalorieTarget
            proteinTarget = settings.proteinTarget
            carbsTarget = settings.carbsTarget
            fatTarget = settings.fatTarget
            apiKey = settings.openAIApiKey ?? ""
        }
    }
    
    private func applyCalculatedMacros() {
        let macros = calculatedMacros
        
        withAnimation {
            proteinTarget = macros.protein
            carbsTarget = macros.carbs
            fatTarget = macros.fat
        }
        
        // Save to settings
        SettingsManager.shared.proteinTarget = proteinTarget
        SettingsManager.shared.carbsTarget = carbsTarget
        SettingsManager.shared.fatTarget = fatTarget
    }
}

struct APIKeyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Why provide your own API key?")
                        .font(.headline)
                    
                    Text("QuickCalories uses OpenAI's GPT-4o-mini model to convert natural language into nutritional data. The free tier includes 1 AI request per day.")
                        .font(.body)
                    
                    Text("If you have your own OpenAI API key, you can:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Make unlimited AI log requests", systemImage: "checkmark.circle.fill")
                        Label("Pay only for what you use (typically < $0.01 per request)", systemImage: "checkmark.circle.fill")
                        Label("Bypass in-app subscription", systemImage: "checkmark.circle.fill")
                    }
                    .font(.body)
                    
                    Divider()
                    
                    Text("How to get an API key:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Visit platform.openai.com")
                        Text("2. Create an account or sign in")
                        Text("3. Navigate to API Keys")
                        Text("4. Create a new secret key")
                        Text("5. Copy and paste it above")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    
                    Text("⚠️ Keep your API key secure. Never share it publicly.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("API Key Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
