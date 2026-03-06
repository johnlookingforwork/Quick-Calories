//
//  Configuration.swift
//  QuickCalories
//
//  Configuration management for API keys and secrets
//  Supports both local development and Xcode Cloud builds
//

import Foundation

enum Configuration {
    
    // MARK: - Configuration Keys
    
    enum Keys {
        static let proxyURL = "PROXY_URL"
        static let appSecret = "APP_SECRET"
    }
    
    // MARK: - Public Interface
    
    /// The URL for the OpenAI proxy server
    static var proxyURL: String {
        // Priority 1: Xcode environment variables (for local development)
        if let url = ProcessInfo.processInfo.environment[Keys.proxyURL],
           !url.isEmpty {
            return url
        }
        
        // Priority 2: Info.plist (Xcode Cloud build-time injection)
        if let url = Bundle.main.object(forInfoDictionaryKey: Keys.proxyURL) as? String,
           !url.isEmpty {
            return url
        }
        
        // Fallback to default for development
        // This URL is public-facing and doesn't expose secrets
        return "https://calorie-app-proxy.vercel.app/api/proxy"
    }
    
    /// The app secret for authenticating with the proxy
    static var appSecret: String {
        // Priority 1: Xcode environment variables (for local development)
        if let secret = ProcessInfo.processInfo.environment[Keys.appSecret],
           !secret.isEmpty {
            return secret
        }
        
        // Priority 2: Info.plist (Xcode Cloud build-time injection)
        if let secret = Bundle.main.object(forInfoDictionaryKey: Keys.appSecret) as? String,
           !secret.isEmpty {
            return secret
        }
        
        // Priority 3: UserDefaults (set by developer in settings UI)
        if let devSecret = UserDefaults.standard.string(forKey: "dev_app_secret"),
           !devSecret.isEmpty {
            return devSecret
        }
        
        // Last resort: Return empty and let developer configure
        return ""
    }
    
    /// Check if configuration is valid
    static var isConfigured: Bool {
        !appSecret.isEmpty && !proxyURL.isEmpty
    }
}
