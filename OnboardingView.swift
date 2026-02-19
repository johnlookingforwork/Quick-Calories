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
                    
                    FeaturePage(
                        icon: "chart.bar.fill",
                        title: "Track Your Progress",
                        description: "Monitor calories, protein, carbs, and fat with beautiful visualizations",
                        color: .green
                    )
                    .tag(2)
                    
                    FeaturePage(
                        icon: "target",
                        title: "Reach Your Goals",
                        description: "Set personalized targets and watch your daily progress",
                        color: .orange
                    )
                    .tag(3)
                    
                    GetStartedPage {
                        withAnimation {
                            showTargetSetup = true
                        }
                    }
                    .tag(4)
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

struct GetStartedPage: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                
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

#Preview {
    OnboardingView {
        print("Onboarding complete")
    }
}
