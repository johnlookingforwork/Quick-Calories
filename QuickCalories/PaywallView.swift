//
//  PaywallView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("Unlimited AI Logging")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Log meals instantly with unlimited AI requests")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited AI Requests",
                            description: "Log as many meals as you want, whenever you want"
                        )
                        
                        FeatureRow(
                            icon: "clock.fill",
                            title: "Instant Processing",
                            description: "Natural language to nutrition data in seconds"
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            title: "Always Improving",
                            description: "Powered by the latest OpenAI models"
                        )
                        
                        FeatureRow(
                            icon: "lock.fill",
                            title: "Private & Secure",
                            description: "Your data stays on your device"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing (Placeholder - Replace with real StoreKit products)
                    VStack(spacing: 16) {
                        PricingCard(
                            title: "Monthly",
                            price: "$2.99",
                            period: "per month",
                            isRecommended: false
                        )
                        
                        PricingCard(
                            title: "Annual",
                            price: "$24.99",
                            period: "per year",
                            isRecommended: true,
                            savings: "Save 30%"
                        )
                    }
                    .padding(.horizontal)
                    
                    // CTA
                    Button {
                        purchaseSubscription()
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start Free Trial")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isPurchasing)
                    
                    // Alternative
                    VStack(spacing: 8) {
                        Text("Or use your own OpenAI API key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("Learn More") {
                            // This would navigate to settings or show info
                            dismiss()
                        }
                        .font(.caption)
                    }
                    
                    // Legal
                    VStack(spacing: 4) {
                        Text("7-day free trial, then auto-renews")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Link("Terms", destination: URL(string: "https://example.com/terms")!)
                            Text("•")
                            Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                            Text("•")
                            Button("Restore") {
                                restorePurchases()
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 32)
                }
            }
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
    }
    
    private func purchaseSubscription() {
        isPurchasing = true
        
        // TODO: Implement actual StoreKit 2 purchase flow
        // For now, just simulate a purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In production, this would be set after successful purchase verification
            // SettingsManager.shared.hasActiveSubscription = true
            isPurchasing = false
            dismiss()
        }
    }
    
    private func restorePurchases() {
        // TODO: Implement StoreKit 2 restore purchases
        print("Restore purchases")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let isRecommended: Bool
    var savings: String? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            if isRecommended {
                Text("BEST VALUE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let savings = savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRecommended ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

#Preview {
    PaywallView()
}
