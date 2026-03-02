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
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var selectedProduct: Product?
    @State private var errorMessage: String?
    @State private var showAPIKeySheet = false
    
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
                    
                    // Pricing - Real StoreKit Products
                    VStack(spacing: 16) {
                        if subscriptionManager.products.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                Button {
                                    selectedProduct = product
                                } label: {
                                    ProductPricingCard(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        isRecommended: product.id.contains("annual")
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
                            Text(selectedProduct == nil ? "Select a Plan" : "Start Free Trial")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct == nil ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isPurchasing || selectedProduct == nil)
                    
                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    // Alternative
                    VStack(spacing: 8) {
                        Text("Or use your own OpenAI API key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("Learn More") {
                            showAPIKeySheet = true
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
                            Link("Privacy", destination: URL(string: "https://www.quickcaloriesapp.com/privacy")!)
                            Text("•")
                            Button("Restore") {
                                Task {
                                    await restorePurchases()
                                }
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
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeyConfigView()
            }
        }
        .task {
            // Load products when view appears
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
            
            // Auto-select the annual plan (recommended)
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.product(for: .annual)
            }
        }
    }
    
    private func purchaseSubscription() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await subscriptionManager.purchase(product)
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func restorePurchases() async {
        await subscriptionManager.restorePurchases()
        
        // Dismiss if subscription was restored
        if subscriptionManager.hasActiveSubscription {
            dismiss()
        }
    }
}

// MARK: - Product Pricing Card

struct ProductPricingCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    
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
                    Text(product.displayName)
                        .font(.headline)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(product.id.contains("annual") ? "per year" : "per month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isRecommended, let monthlyPrice = calculateMonthlySavings() {
                    Text(monthlyPrice)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private func calculateMonthlySavings() -> String? {
        // You can calculate savings here if you want
        // For now, just show a simple "Save X%" message
        if product.id.contains("annual") {
            return "Save 30%"
        }
        return nil
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

#Preview {
    PaywallView()
}
