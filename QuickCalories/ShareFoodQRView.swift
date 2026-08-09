//
//  ShareFoodQRView.swift
//  QuickCalories
//
//  Created by John N on 8/8/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareFoodQRView: View {
    @Environment(\.dismiss) private var dismiss
    let food: SavedFood
    @State private var qrImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Food details preview card
                VStack(spacing: 16) {
                    Text(food.foodName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(food.calories) cal • \(food.servingSize, specifier: "%.1f") \(food.unit)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        MacroShareBadge(name: "Protein", amount: food.protein, color: .red)
                        MacroShareBadge(name: "Carbs", amount: food.carbs, color: .blue)
                        MacroShareBadge(name: "Fat", amount: food.fat, color: .yellow)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // QR code display
                if let qrImage = qrImage {
                    VStack(spacing: 12) {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none) // keeps QR code edges razor-sharp
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                        
                        Text("Ask another user to scan this code in QuickCalories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ProgressView()
                        .frame(width: 232, height: 232)
                }
                
                Spacer()
                
                if let qrImage = qrImage {
                    ShareLink(
                        item: Image(uiImage: qrImage),
                        preview: SharePreview("QR Code for \(food.foodName)", image: Image(uiImage: qrImage))
                    ) {
                        Label("Share QR Code Image", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            .navigationTitle("Share Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: generateQR)
        }
    }
    
    private func generateQR() {
        let payload: [String: Any] = [
            "type": "quickcalories_food",
            "name": food.foodName,
            "servingSize": food.servingSize,
            "unit": food.unit,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        // High error correction to improve scanning capability
        filter.correctionLevel = "H"
        
        if let output = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaled = output.transformed(by: transform)
            let context = CIContext()
            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

struct MacroShareBadge: View {
    let name: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(amount))g")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
