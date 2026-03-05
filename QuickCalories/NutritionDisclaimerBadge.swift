//
//  NutritionDisclaimerBadge.swift
//  QuickCalories
//
//  Created by John N on 3/5/26.
//

import SwiftUI

/// A small badge that indicates nutritional data is AI-estimated
/// Can be added near nutrition displays for transparency
struct NutritionDisclaimerBadge: View {
    @State private var showDataSources = false
    
    var body: some View {
        Button {
            showDataSources = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                Text("AI Estimate")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .sheet(isPresented: $showDataSources) {
            DataSourcesView()
        }
    }
}

/// Extension to easily add disclaimer to views
extension View {
    /// Adds a small disclaimer badge below the view
    func withNutritionDisclaimer() -> some View {
        VStack(spacing: 8) {
            self
            NutritionDisclaimerBadge()
        }
    }
}

#Preview {
    VStack {
        Text("Calories: 350")
            .font(.title)
        
        NutritionDisclaimerBadge()
    }
    .padding()
}
