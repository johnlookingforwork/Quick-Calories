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
    @State private var apiKey = ""
    @State private var showAPIKeyInfo = false
    @State private var showTargetSetup = false
    @State private var showRecalculateConfirmation = false
    
    private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                // Display current targets
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(calorieTarget)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                        
                        Text("calories per day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        MacroTargetBadge(name: "Protein", amount: proteinTarget, color: .red)
                        MacroTargetBadge(name: "Carbs", amount: carbsTarget, color: .blue)
                        MacroTargetBadge(name: "Fat", amount: fatTarget, color: .yellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                Button {
                    showTargetSetup = true
                } label: {
                    Label("Edit Targets", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if settings.hasProfileData {
                    Button {
                        showRecalculateConfirmation = true
                    } label: {
                        Label("Recalculate from Profile", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Daily Targets")
            } footer: {
                if settings.hasProfileData {
                    Text("Based on your profile: \(settings.userAge) years old, \(settings.useMetricSystem ? String(format: "%.0f kg", settings.userWeight) : String(format: "%.0f lbs", settings.userWeight.kgToLbs))")
                }
            }
            
            // Profile section (if exists)
            if settings.hasProfileData {
                Section("Your Profile") {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(settings.userAge) years")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        if settings.useMetricSystem {
                            Text(String(format: "%.0f kg", settings.userWeight))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(format: "%.0f lbs", settings.userWeight.kgToLbs))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        if settings.useMetricSystem {
                            Text(String(format: "%.0f cm", settings.userHeight))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(format: "%.0f in", settings.userHeight.cmToInches))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Activity Level")
                        Spacer()
                        Text(settings.activityLevel)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text(settings.goalType)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                HStack {
                    Text("OpenAI API Key")
                    Spacer()
                    Button {
                        showAPIKeyInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }
                
                SecureField("Optional - sk-...", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: apiKey) { _, newValue in
                        SettingsManager.shared.openAIApiKey = newValue.isEmpty ? nil : newValue
                    }
                
                if !apiKey.isEmpty {
                    Button("Clear API Key", role: .destructive) {
                        apiKey = ""
                        SettingsManager.shared.openAIApiKey = nil
                    }
                }
            } header: {
                Text("AI Configuration")
            } footer: {
                if apiKey.isEmpty {
                    Text("Supply your own OpenAI API key to bypass the 1 request per day limit, or subscribe for unlimited requests.")
                } else {
                    Text("Using your own API key. You have unlimited AI requests and will be billed directly by OpenAI.")
                }
            }
            
            // Only show usage section if no API key is provided
            if apiKey.isEmpty {
                Section("Usage") {
                    HStack {
                        Text("Daily AI Requests")
                        Spacer()
                        Text("\(SettingsManager.shared.dailyAIRequestCount) / 1")
                            .foregroundStyle(.secondary)
                    }
                    
                    if let lastReset = SettingsManager.shared.lastRequestResetDate {
                        HStack {
                            Text("Resets at Midnight")
                            Spacer()
                            Text(lastReset, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAPIKeyInfo) {
            APIKeyInfoView()
        }
        .sheet(isPresented: $showTargetSetup) {
            CalorieTargetSetupView(
                dailyCalorieTarget: $calorieTarget,
                proteinTarget: $proteinTarget,
                carbsTarget: $carbsTarget,
                fatTarget: $fatTarget,
                isOnboarding: false
            )
        }
        .confirmationDialog(
            "Recalculate Targets",
            isPresented: $showRecalculateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Recalculate") {
                recalculateTargets()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update your daily targets based on your saved profile information.")
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: calorieTarget) { _, newValue in
            SettingsManager.shared.dailyCalorieTarget = newValue
        }
        .onChange(of: proteinTarget) { _, newValue in
            SettingsManager.shared.proteinTarget = newValue
        }
        .onChange(of: carbsTarget) { _, newValue in
            SettingsManager.shared.carbsTarget = newValue
        }
        .onChange(of: fatTarget) { _, newValue in
            SettingsManager.shared.fatTarget = newValue
        }
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared
        calorieTarget = settings.dailyCalorieTarget
        proteinTarget = settings.proteinTarget
        carbsTarget = settings.carbsTarget
        fatTarget = settings.fatTarget
        apiKey = settings.openAIApiKey ?? ""
    }
    
    private func recalculateTargets() {
        SettingsManager.shared.recalculateFromProfile()
        loadSettings()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct MacroTargetBadge: View {
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
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("\(Int(amount))g")
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
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
