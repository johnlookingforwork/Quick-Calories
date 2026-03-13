//
//  OpenAIService.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import Foundation
import UIKit

struct NutritionResponse: Sendable, Codable {
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    // Data source information for App Store compliance
    var dataSource: String {
        "AI-generated estimates based on USDA National Nutrient Database and common nutrition references"
    }
    
    var disclaimer: String {
        "Nutritional values are estimates and may vary. For medical or dietary decisions, consult a healthcare professional."
    }
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case calories
        case protein
        case carbs
        case fat
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.foodName = try container.decode(String.self, forKey: .foodName)
        self.calories = try container.decode(Int.self, forKey: .calories)
        self.protein = try container.decode(Double.self, forKey: .protein)
        self.carbs = try container.decode(Double.self, forKey: .carbs)
        self.fat = try container.decode(Double.self, forKey: .fat)
    }
}

enum OpenAIError: LocalizedError {
    case invalidResponse
    case rateLimitExceeded
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unable to parse nutritional data"
        case .rateLimitExceeded:
            return "Daily AI request limit reached"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

actor OpenAIService {
    static let shared = OpenAIService()
    
    private var proxyURL: String {
        get async {
            await MainActor.run { Configuration.proxyURL }
        }
    }
    
    private var appSecret: String {
        get async {
            await MainActor.run { Configuration.appSecret }
        }
    }
    
    private init() {}
    
    func parseFood(_ input: String) async throws -> NutritionResponse {
        let settings = await SettingsManager.shared
        
        // Check rate limiting
        guard await settings.canMakeAIRequest() else {
            throw OpenAIError.rateLimitExceeded
        }
        
        let systemPrompt = """
        You are a nutritional database assistant. Convert the user's text into a JSON object with keys: \
        calories, protein, carbs, fat, and food_name. Base estimates on standard nutritional databases \
        like USDA National Nutrient Database and common food composition tables. Use average values for \
        typical serving sizes. When the user mentions a restaurant or brand by an informal or abbreviated \
        name (e.g. "mcdonalds" or "mcd" for McDonald's, "cfa" or "chick fil a" for Chick-fil-A, \
        "bk" for Burger King, "wingstop", "chipotle", etc.), use that chain's known menu item \
        nutritional data rather than generic estimates. Return ONLY the JSON, no additional text.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "temperature": 0.3,
            "max_tokens": 200
        ]
        
        return try await sendRequest(requestBody)
    }
    
    func parseFood(from image: UIImage, context: String? = nil) async throws -> NutritionResponse {
        let settings = await SettingsManager.shared
        
        // Check rate limiting
        guard await settings.canMakeAIRequest() else {
            throw OpenAIError.rateLimitExceeded
        }
        
        // Process image for Vision API
        let base64Image = try await ImageProcessor.processForVisionAPI(image)
        
        // Extract camera metadata
        let metadata = await ImageMetadataExtractor.extractMetadata(from: image)
        
        // Build enhanced context with camera info
        let enhancedContext = buildEnhancedContext(
            userContext: context,
            metadata: metadata
        )
        
        let systemPrompt = """
        You are a nutritional database assistant. Analyze the food in this image and return a JSON object with keys: \
        calories, protein, carbs, fat, and food_name. Base estimates on standard nutritional databases \
        like USDA National Nutrient Database and common food composition tables. Use average values for \
        typical serving sizes. If the image or context mentions a restaurant or brand by an informal or \
        abbreviated name (e.g. "mcdonalds" or "mcd" for McDonald's, "cfa" or "chick fil a" for Chick-fil-A, \
        "bk" for Burger King, "wingstop", "chipotle", etc.), use that chain's known menu item \
        nutritional data rather than generic estimates.
        
        IMPORTANT FOR SIZE ESTIMATION:
        Use the provided camera metadata (device model, lens type, focal length) to better estimate portion sizes. \
        Different iPhone cameras have different field of view and perspective distortion. Ultra-wide lenses make \
        objects appear smaller; telephoto lenses make them appear larger. Adjust your portion size estimates \
        accordingly based on the camera used. Consider the device model's known physical dimensions for scale reference.
        
        Return ONLY the JSON, no additional text.
        """
        
        // Build message content with image and enhanced text context
        let userContent: [[String: Any]] = [
            [
                "type": "text",
                "text": enhancedContext
            ],
            [
                "type": "image_url",
                "image_url": [
                    "url": base64Image
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "temperature": 0.3,
            "max_tokens": 200
        ]
        
        return try await sendRequest(requestBody)
    }
    
    // MARK: - Helper Methods
    
    private func buildEnhancedContext(
        userContext: String?,
        metadata: CameraMetadata?
    ) -> String {
        var contextParts: [String] = []
        
        // User's text context
        if let context = userContext {
            contextParts.append("User context: \(context)")
        } else {
            contextParts.append("Analyze this food image and provide nutritional information.")
        }
        
        // Camera metadata
        if let metadata = metadata {
            var cameraInfo = "Camera: \(metadata.deviceModel)"
            
            if let lens = metadata.cameraLensType {
                cameraInfo += ", \(lens) lens"
            }
            
            if let focal = metadata.focalLength35mmEquivalent {
                cameraInfo += ", \(focal)mm equivalent"
            }
            
            if let aperture = metadata.aperture {
                cameraInfo += ", f/\(String(format: "%.1f", aperture))"
            }
            
            cameraInfo += ", image size: \(metadata.imageWidth)x\(metadata.imageHeight)px"
            
            contextParts.append(cameraInfo)
        }
        
        return contextParts.joined(separator: "\n")
    }
    
    // MARK: - Private Helpers
    
    private func decodeNutrition(from data: Data) throws -> NutritionResponse {
        return try JSONDecoder().decode(NutritionResponse.self, from: data)
    }
    
    private func sendRequest(_ requestBody: [String: Any]) async throws -> NutritionResponse {
        let settings = await SettingsManager.shared
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.invalidResponse
        }
        
        let proxyURLString = await proxyURL
        let appSecretString = await appSecret
        
        guard let url = URL(string: proxyURLString) else {
            throw OpenAIError.apiError("Invalid proxy URL configuration")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appSecretString, forHTTPHeaderField: "x-app-secret")
        request.httpBody = jsonData
        request.timeoutInterval = 30 // Longer timeout for vision API
        
        // If user provided their own API key, send it
        if let apiKey = await settings.openAIApiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                }
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            // Parse OpenAI response
            struct OpenAIResponse: Codable {
                struct Choice: Codable {
                    struct Message: Codable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = openAIResponse.choices.first?.message.content else {
                throw OpenAIError.invalidResponse
            }
            
            // Extract JSON from response (handling potential markdown code blocks)
            let cleanedContent = content
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            guard let nutritionData = cleanedContent.data(using: String.Encoding.utf8) else {
                throw OpenAIError.invalidResponse
            }
            
            let nutrition = try decodeNutrition(from: nutritionData)
            
            // Increment request count
            await settings.incrementAIRequestCount()
            
            return nutrition
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
}
