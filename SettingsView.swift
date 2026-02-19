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
    
    var body: some View {
        Form {
            Section("Daily Targets") {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("2000", value: $calorieTarget, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: calorieTarget) { _, newValue in
                            SettingsManager.shared.dailyCalorieTarget = newValue
                        }
                    Text("cal")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Macro Targets") {
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("150", value: $proteinTarget, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: proteinTarget) { _, newValue in
                            SettingsManager.shared.proteinTarget = newValue
                        }
                    Text("g")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("200", value: $carbsTarget, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: carbsTarget) { _, newValue in
                            SettingsManager.shared.carbsTarget = newValue
                        }
                    Text("g")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("67", value: $fatTarget, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: fatTarget) { _, newValue in
                            SettingsManager.shared.fatTarget = newValue
                        }
                    Text("g")
                        .foregroundStyle(.secondary)
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
                Text("Supply your own OpenAI API key to bypass the 1 request per day limit, or subscribe for unlimited requests.")
            }
            
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
