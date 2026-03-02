//
//  DeveloperConfigView.swift
//  QuickCalories
//
//  Created for local development configuration
//

import SwiftUI

struct DeveloperConfigView: View {
    @State private var appSecret = UserDefaults.standard.string(forKey: "dev_app_secret") ?? ""
    @State private var showingSaved = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("For local development, enter your app secret here. This is stored locally and never committed to git.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Developer Configuration")
                }
                
                Section {
                    SecureField("App Secret", text: $appSecret)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                    
                    if !Configuration.appSecret.isEmpty {
                        Label("Configured ✓", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("App Secret")
                } footer: {
                    Text("This must match the APP_SECRET in your Vercel deployment. Get this from your Vercel environment variables.")
                }
                
                Section {
                    Text(Configuration.proxyURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Proxy URL")
                } footer: {
                    Text("This is the URL of your Vercel proxy server.")
                }
                
                Section {
                    Button("Save Configuration") {
                        UserDefaults.standard.set(appSecret, forKey: "dev_app_secret")
                        showingSaved = true
                        
                        // Dismiss after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                    .disabled(appSecret.isEmpty)
                }
            }
            .navigationTitle("Developer Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Configuration Saved", isPresented: $showingSaved) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your app secret has been saved to UserDefaults.")
            }
        }
    }
}

#Preview {
    DeveloperConfigView()
}
