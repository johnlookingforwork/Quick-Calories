//
//  OnboardingView.swift
//  QuickCalories
//
//  Created by John N on 2/18/26.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showTargetSetup = false
    @State private var dailyCalorieTarget = 2000
    @State private var proteinTarget = 150.0
    @State private var carbsTarget = 200.0
    @State private var fatTarget = 67.0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            if !showTargetSetup {
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    FeaturePage(
                        icon: "sparkles",
                        title: "AI-Powered Logging",
                        description: "Just describe your meal naturally and let AI calculate the nutrition for you",
                        color: .blue
                    )
                    .tag(1)
                    
                    PhotoLoggingPage()
                        .tag(2)
                    
                    FeaturePage(
                        icon: "chart.bar.fill",
                        title: "Track Your Progress",
                        description: "Monitor calories, protein, carbs, and fat with beautiful visualizations",
                        color: .green
                    )
                    .tag(3)
                    
                    FeaturePage(
                        icon: "target",
                        title: "Reach Your Goals",
                        description: "Set personalized targets and watch your daily progress",
                        color: .orange
                    )
                    .tag(4)
                    
                    PrivacyPage()
                        .tag(5)
                    
                    GetStartedPage {
                        withAnimation {
                            showTargetSetup = true
                        }
                    }
                    .tag(6)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            } else {
                CalorieTargetSetupView(
                    dailyCalorieTarget: $dailyCalorieTarget,
                    proteinTarget: $proteinTarget,
                    carbsTarget: $carbsTarget,
                    fatTarget: $fatTarget,
                    isOnboarding: true
                ) {
                    completeOnboarding()
                }
            }
        }
    }
    
    private func completeOnboarding() {
        SettingsManager.shared.hasCompletedOnboarding = true
        onComplete()
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue.gradient)
                
                Text("QuickCalories")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                
                Text("Track your nutrition with ease")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

struct FeaturePage: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(color.gradient)
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

struct PrivacyPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                
                VStack(spacing: 12) {
                    Text("Your Privacy Matters")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("All your data stays on your device")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    PrivacyFeatureRow(
                        icon: "iphone",
                        text: "Everything stored locally"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "xmark.circle",
                        text: "No data collection"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "hand.raised.fill",
                        text: "No tracking or analytics"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "checkmark.shield.fill",
                        text: "Your health info is private"
                    )
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GetStartedPage: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 12) {
                    Text("Ready to Get Started?")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's set up your personalized calorie and macro targets")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            Button {
                onGetStarted()
            } label: {
                Text("Set Up Targets")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

struct PhotoLoggingPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Camera icon with sparkles
                ZStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.purple.gradient)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(.yellow)
                        .offset(x: 35, y: -30)
                }
                
                VStack(spacing: 12) {
                    Text("Snap a Picture to Log")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Take a photo of your food and AI will instantly identify it and calculate the nutrition")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Visual example cards
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Snap a photo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Take a picture of your meal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI analyzes it")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Instant nutrition breakdown")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm & log")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Review and save to your diary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

#Preview {
    OnboardingView {
        print("Onboarding complete")
    }
}
