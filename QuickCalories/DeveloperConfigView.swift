//
//  DeveloperConfigView.swift
//  QuickCalories
//
//  Created for local development configuration
//

import SwiftUI
import StoreKit

struct DeveloperConfigView: View {
    @State private var appSecret = UserDefaults.standard.string(forKey: "dev_app_secret") ?? ""
    @State private var showingSaved = false
    @State private var showDebugInfo = false
    @State private var showStoreKitDebug = false
    @Environment(\.dismiss) private var dismiss
    
    private var subscriptionManager = SubscriptionManager.shared
    
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
                
                // MARK: - Debug Section
                Section {
                    Button {
                        showDebugInfo.toggle()
                    } label: {
                        HStack {
                            Label("Show Debug Info", systemImage: "ladybug.fill")
                            Spacer()
                            Image(systemName: showDebugInfo ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if showDebugInfo {
                        VStack(alignment: .leading, spacing: 12) {
                            DebugInfoRow(
                                title: "Configuration Valid",
                                value: Configuration.isConfigured ? "✅ YES" : "❌ NO",
                                color: Configuration.isConfigured ? .green : .red
                            )
                            
                            Divider()
                            
                            Text("Active Configuration")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "Proxy URL (Active)",
                                value: Configuration.proxyURL.isEmpty ? "(empty)" : Configuration.proxyURL,
                                color: .blue
                            )
                            
                            DebugInfoRow(
                                title: "App Secret (Active)",
                                value: Configuration.appSecret.isEmpty ? "(empty)" : "••••••••" + Configuration.appSecret.suffix(4),
                                color: Configuration.appSecret.isEmpty ? .red : .green
                            )
                            
                            Divider()
                            
                            Text("Priority 1: Environment Variables")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "PROXY_URL",
                                value: ProcessInfo.processInfo.environment["PROXY_URL"] ?? "(not set)",
                                color: ProcessInfo.processInfo.environment["PROXY_URL"] != nil ? .green : .secondary
                            )
                            
                            DebugInfoRow(
                                title: "APP_SECRET",
                                value: {
                                    if let secret = ProcessInfo.processInfo.environment["APP_SECRET"], !secret.isEmpty {
                                        return "••••••••" + secret.suffix(4)
                                    }
                                    return "(not set)"
                                }(),
                                color: ProcessInfo.processInfo.environment["APP_SECRET"] != nil ? .green : .secondary
                            )
                            
                            Divider()
                            
                            Text("Priority 2: Info.plist")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "PROXY_URL",
                                value: Bundle.main.object(forInfoDictionaryKey: "PROXY_URL") as? String ?? "(not set)",
                                color: .secondary
                            )
                            
                            DebugInfoRow(
                                title: "APP_SECRET",
                                value: {
                                    if let secret = Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String, !secret.isEmpty {
                                        return "••••••••" + secret.suffix(4)
                                    }
                                    return "(not set)"
                                }(),
                                color: .secondary
                            )
                            
                            Divider()
                            
                            Text("Priority 3: UserDefaults")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "dev_app_secret",
                                value: {
                                    if let secret = UserDefaults.standard.string(forKey: "dev_app_secret"), !secret.isEmpty {
                                        return "••••••••" + secret.suffix(4)
                                    }
                                    return "(not set)"
                                }(),
                                color: .secondary
                            )
                        }
                        .font(.caption)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Debug Information")
                }
                
                // MARK: - StoreKit Debug Section
                Section {
                    Button {
                        showStoreKitDebug.toggle()
                    } label: {
                        HStack {
                            Label("StoreKit Debug Info", systemImage: "cart.fill")
                            Spacer()
                            Image(systemName: showStoreKitDebug ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if showStoreKitDebug {
                        VStack(alignment: .leading, spacing: 12) {
                            // Bundle ID
                            DebugInfoRow(
                                title: "Bundle ID",
                                value: Bundle.main.bundleIdentifier ?? "(not found)",
                                color: .blue
                            )
                            
                            Divider()
                            
                            // Expected Product IDs
                            Text("Expected Product IDs")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "Annual",
                                value: SubscriptionTier.annual.rawValue,
                                color: .blue
                            )
                            
                            DebugInfoRow(
                                title: "Monthly",
                                value: SubscriptionTier.monthly.rawValue,
                                color: .blue
                            )
                            
                            Divider()
                            
                            // Products Loaded
                            Text("Products Loaded from App Store")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "Count",
                                value: "\(subscriptionManager.products.count)",
                                color: subscriptionManager.products.isEmpty ? .red : .green
                            )
                            
                            if subscriptionManager.products.isEmpty {
                                Text("⚠️ No products loaded!")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(.vertical, 4)
                                
                                Text("Possible reasons:")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Product IDs don't match Bundle ID")
                                    Text("• Products not approved in App Store Connect")
                                    Text("• Paid Applications Agreement not signed")
                                    Text("• Not using TestFlight build")
                                    Text("• StoreKit config file selected in scheme")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                            } else {
                                ForEach(subscriptionManager.products, id: \.id) { product in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("✅ \(product.displayName)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.green)
                                        
                                        Text(product.id)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                        
                                        Text(product.displayPrice)
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            Divider()
                            
                            // Active Subscriptions
                            Text("Active Subscriptions")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "Count",
                                value: "\(subscriptionManager.purchasedSubscriptions.count)",
                                color: subscriptionManager.hasActiveSubscription ? .green : .secondary
                            )
                            
                            DebugInfoRow(
                                title: "Has Active Subscription",
                                value: subscriptionManager.hasActiveSubscription ? "✅ YES" : "❌ NO",
                                color: subscriptionManager.hasActiveSubscription ? .green : .secondary
                            )
                            
                            Divider()
                            
                            // Configuration Status
                            Text("Build Configuration")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            
                            DebugInfoRow(
                                title: "Using Local StoreKit Config",
                                value: subscriptionManager.isUsingLocalConfiguration ? "⚠️ YES" : "✅ NO",
                                color: subscriptionManager.isUsingLocalConfiguration ? .orange : .green
                            )
                            
                            if subscriptionManager.isUsingLocalConfiguration {
                                Text("⚠️ You're testing with local .storekit file. Real purchases won't work until you test with a TestFlight build.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                    .padding(.top, 4)
                            }
                            
                            Divider()
                            
                            // Refresh Button
                            Button {
                                Task {
                                    await subscriptionManager.loadProducts()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reload Products")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.caption)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("StoreKit Diagnostics")
                } footer: {
                    Text("Check console logs in Xcode for detailed StoreKit error messages.")
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

// MARK: - Helper Views

struct DebugInfoRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(color)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    DeveloperConfigView()
}
