//
//  SubscriptionManager.swift
//  QuickCalories
//
//  Created by John N on 2/28/26.
//

import Foundation
import StoreKit
import Observation

enum SubscriptionTier: String, CaseIterable {
    case monthly = "com.johnn.quickcalories.subscription.monthly"
    case annual = "com.johnn.quickcalories.subscription.annual"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase"
        case .productNotFound:
            return "Product not found"
        }
    }
}

@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    private(set) var products: [Product] = []
    private(set) var purchasedSubscriptions: [Product] = []
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load products and update status on next run loop
        // This prevents blocking the main thread during app launch
        Task { @MainActor in
            do {
                await loadProducts()
                await updateSubscriptionStatus()
            } catch {
                print("❌ Failed to initialize SubscriptionManager: \(error)")
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load products from the App Store
    func loadProducts() async {
        do {
            let productIdentifiers = SubscriptionTier.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIdentifiers)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            // Don't crash - just use empty products array
            products = []
        }
    }
    
    /// Purchase a subscription
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Finish the transaction
            await transaction.finish()
            
            print("✅ Purchase successful: \(product.id)")
            
        case .userCancelled:
            print("ℹ️ User cancelled purchase")
            
        case .pending:
            print("⏳ Purchase pending")
            
        @unknown default:
            break
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }
    
    /// Check if user has an active subscription
    var hasActiveSubscription: Bool {
        !purchasedSubscriptions.isEmpty
    }
    
    // MARK: - Private Methods
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updateSubscriptionStatus()
                    await transaction?.finish()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
    
    /// Verify a transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    /// Update the subscription status
    @MainActor
    private func updateSubscriptionStatus() async {
        var purchasedSubscriptions: [Product] = []
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if it's an active auto-renewable subscription
                if transaction.productType == .autoRenewable,
                   !transaction.isUpgraded {
                    
                    // Find the product
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(product)
                    }
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedSubscriptions = purchasedSubscriptions
        
        // Update SettingsManager
        SettingsManager.shared.hasActiveSubscription = hasActiveSubscription
        
        print("ℹ️ Active subscriptions: \(purchasedSubscriptions.count)")
    }
    
    /// Get product by tier
    func product(for tier: SubscriptionTier) -> Product? {
        products.first { $0.id == tier.rawValue }
    }
}
