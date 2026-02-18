//
//  AILogView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct AILogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    @State private var foodInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date indicator
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Text input
                VStack(spacing: 12) {
                    TextEditor(text: $foodInput)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                        .overlay(
                            Group {
                                if foodInput.isEmpty {
                                    Text("Describe your meal...\ne.g., 3 scrambled eggs and sourdough toast")
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Log button
                Button(action: logFood) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Log with AI")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(foodInput.isEmpty || isLoading ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(foodInput.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Log with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func logFood() {
        guard !foodInput.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let nutrition = try await OpenAIService.shared.parseFood(foodInput)
                
                await MainActor.run {
                    let entry = FoodEntry(
                        foodName: nutrition.foodName,
                        calories: nutrition.calories,
                        protein: nutrition.protein,
                        carbs: nutrition.carbs,
                        fat: nutrition.fat,
                        timestamp: date  // Use provided date
                    )
                    modelContext.insert(entry)
                    
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    dismiss()
                }
            } catch OpenAIError.rateLimitExceeded {
                await MainActor.run {
                    isLoading = false
                    showPaywall = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AILogView(date: Date())
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
