//
//  ContentView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showOnboarding = !SettingsManager.shared.hasCompletedOnboarding
    
    var body: some View {
        DashboardView()
            .sheet(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                }
                .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
