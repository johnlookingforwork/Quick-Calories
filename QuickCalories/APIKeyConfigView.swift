//
//  APIKeyConfigView.swift
//  QuickCalories
//
//  Created by John N on 2/28/26.
//

import SwiftUI

struct APIKeyConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var showSuccess = false
    
    var onAPIKeySaved: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Bring Your Own API Key")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Use your own OpenAI API key for unlimited AI requests without a subscription")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(
                            icon: "checkmark.circle.fill",
                            text: "Unlimited AI meal logging",
                            color: .green
                        )
                        BenefitRow(
                            icon: "dollarsign.circle.fill",
                            text: "Pay only for what you use (~$0.01 per request)",
                            color: .green
                        )
                        BenefitRow(
                            icon: "lock.fill",
                            text: "Direct connection to OpenAI (secure)",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Get Your API Key:")
                            .font(.headline)
                        
                        InstructionStep(
                            number: "1",
                            title: "Sign up at OpenAI",
                            description: "Go to platform.openai.com and create an account"
                        )
                        
                        InstructionStep(
                            number: "2",
                            title: "Add payment method",
                            description: "You'll need to add a credit card to your OpenAI account"
                        )
                        
                        InstructionStep(
                            number: "3",
                            title: "Generate API key",
                            description: "Go to API Keys section and create a new secret key"
                        )
                        
                        InstructionStep(
                            number: "4",
                            title: "Paste it below",
                            description: "Copy and paste your API key into the field below"
                        )
                    }
                    .padding(.horizontal)
                    
                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your OpenAI API Key")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Text("Your API key is stored securely on your device and never shared")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button {
                        saveAPIKey()
                    } label: {
                        Text(apiKey.isEmpty ? "Enter API Key" : "Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(apiKey.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(apiKey.isEmpty)
                    .padding(.horizontal)
                    
                    // Success message
                    if showSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("API Key Saved!")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Help Link
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Get your API key at platform.openai.com")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("API Key Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Load existing API key if available
            apiKey = SettingsManager.shared.openAIApiKey ?? ""
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else { return }
        
        // Save to settings
        SettingsManager.shared.openAIApiKey = trimmedKey
        
        // Show success
        withAnimation {
            showSuccess = true
        }
        
        // Dismiss after a delay and call the callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
            onAPIKeySaved?()
        }
    }
}

// MARK: - Supporting Views

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct InstructionStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    APIKeyConfigView()
}
