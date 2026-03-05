//
//  DataSourcesView.swift
//  QuickCalories
//
//  Created by John N on 3/5/26.
//

import SwiftUI

struct DataSourcesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QuickCalories uses AI technology to estimate nutritional information based on your input.")
                            .font(.body)
                        
                        Text("All nutritional data is generated from AI models trained on publicly available nutrition databases and scientific literature.")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("How It Works")
                }
                
                Section {
                    DataSourceRow(
                        icon: "leaf.fill",
                        title: "USDA National Nutrient Database",
                        description: "Comprehensive database of food composition data maintained by the U.S. Department of Agriculture",
                        url: "https://fdc.nal.usda.gov/"
                    )
                    
                    DataSourceRow(
                        icon: "book.fill",
                        title: "Common Food Composition Tables",
                        description: "Standardized nutritional values from internationally recognized food composition databases",
                        url: nil
                    )
                    
                    DataSourceRow(
                        icon: "brain",
                        title: "AI Processing",
                        description: "OpenAI GPT-4 models trained on nutritional science literature and databases",
                        url: "https://openai.com"
                    )
                } header: {
                    Text("Nutritional Data Sources")
                } footer: {
                    Text("Citations are based on the training data of the AI model, which includes the above sources.")
                }
                
                Section {
                    DataSourceRow(
                        icon: "figure.run",
                        title: "Mifflin-St Jeor Equation",
                        description: "Scientifically validated formula for calculating Basal Metabolic Rate (BMR), published in the American Journal of Clinical Nutrition (1990)",
                        url: "https://pubmed.ncbi.nlm.nih.gov/2305711/"
                    )
                    
                    DataSourceRow(
                        icon: "chart.bar.fill",
                        title: "Activity Level Multipliers",
                        description: "Standard TDEE multipliers based on research from the American College of Sports Medicine and International Society of Sports Nutrition",
                        url: nil
                    )
                    
                    DataSourceRow(
                        icon: "fork.knife",
                        title: "Protein Recommendations",
                        description: "Based on guidelines from the International Society of Sports Nutrition (1.6-2.0g per kg body weight)",
                        url: "https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0177-8"
                    )
                } header: {
                    Text("Calorie & Macro Calculations")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("**Calorie calculation**: BMR (Mifflin-St Jeor) × Activity Multiplier ± Goal Adjustment")
                        Text("**Protein**: Based on body weight (1.6-2.0g/kg)")
                        Text("**Fat**: 30-50% of calories depending on diet type")
                        Text("**Carbs**: Remaining calories after protein and fat")
                        Text("")
                        Text("Goal adjustments: Weight loss (-500 cal/day for ~1 lb/week), Muscle gain (+300 cal/day for lean bulk)")
                    }
                    .font(.caption)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Estimates Only")
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        
                        Text("All nutritional values provided are estimates based on typical serving sizes and average values. Actual nutritional content may vary based on preparation methods, brands, and portion sizes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Label {
                            Text("Not Medical Advice")
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "cross.case.fill")
                                .foregroundStyle(.red)
                        }
                        
                        Text("This app is not a substitute for professional medical advice, diagnosis, or treatment. For dietary decisions related to medical conditions, please consult with a qualified healthcare provider or registered dietitian.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Important Disclaimers")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For more accurate nutritional information:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Check product packaging labels")
                            Text("• Use verified nutrition databases")
                            Text("• Consult with nutrition professionals")
                            Text("• Consider food preparation methods")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Recommendations")
                }
            }
            .navigationTitle("Data Sources & Citations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DataSourceRow: View {
    let icon: String
    let title: String
    let description: String
    let url: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            if let url = url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Text(url)
                            .font(.caption)
                            .lineLimit(1)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DataSourcesView()
}
