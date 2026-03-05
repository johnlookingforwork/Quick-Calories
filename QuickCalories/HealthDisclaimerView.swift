//
//  HealthDisclaimerView.swift
//  QuickCalories
//
//  Created by John N on 3/5/26.
//

import SwiftUI

struct HealthDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasAgreed = false
    
    let onAccept: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon
                    VStack {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Health Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please read before using QuickCalories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // AI-Generated Data
                    DisclaimerSection(
                        icon: "brain",
                        iconColor: .blue,
                        title: "AI-Generated Estimates",
                        content: "All nutritional information in this app is generated using artificial intelligence based on data from the USDA National Nutrient Database and other food composition tables. Values are estimates and may not reflect exact nutritional content."
                    )
                    
                    // Not Medical Advice
                    DisclaimerSection(
                        icon: "cross.case",
                        iconColor: .red,
                        title: "Not Medical Advice",
                        content: "This app is not a substitute for professional medical advice, diagnosis, or treatment. If you have medical conditions, dietary restrictions, or health concerns, consult with a qualified healthcare provider or registered dietitian."
                    )
                    
                    // Accuracy
                    DisclaimerSection(
                        icon: "exclamationmark.triangle",
                        iconColor: .orange,
                        title: "Accuracy May Vary",
                        content: "Actual nutritional values depend on preparation methods, brands, portion sizes, and ingredients. Always verify with product labels when accuracy is critical."
                    )
                    
                    // Data Sources Link
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For detailed information about our data sources:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            // Will be shown in Settings
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("Data Sources & Citations available in Settings")
                                    .font(.footnote)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                    
                    Divider()
                    
                    // Agreement Toggle
                    Toggle(isOn: $hasAgreed) {
                        Text("I understand and agree to use this app for informational purposes only")
                            .font(.footnote)
                    }
                    .toggleStyle(.switch)
                    .tint(.blue)
                }
                .padding()
            }
            .navigationTitle("Health Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onAccept()
                        dismiss()
                    }
                    .disabled(!hasAgreed)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

struct DisclaimerSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HealthDisclaimerView {
        print("Accepted")
    }
}
