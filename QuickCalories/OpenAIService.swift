//
//  OpenAIService.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import Foundation
import UIKit

struct NutritionResponse: Codable {
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case calories
        case protein
        case carbs
        case fat
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
    
    private let proxyURL = Secrets.proxyURL
    private let appSecret = Secrets.appSecret
    
    private init() {}
    
    func parseFood(_ input: String) async throws -> NutritionResponse {
        let settings = SettingsManager.shared
        
        // Check rate limiting
        guard settings.canMakeAIRequest() else {
            throw OpenAIError.rateLimitExceeded
        }
        
        let systemPrompt = """
        You are a nutritional database. Convert the user's text into a JSON object with keys: 
        calories, protein, carbs, fat, and food_name. Use average nutritional values. Return ONLY the JSON.
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
        let settings = SettingsManager.shared
        
        // Check rate limiting
        guard settings.canMakeAIRequest() else {
            throw OpenAIError.rateLimitExceeded
        }
        
        // Process image for Vision API
        let base64Image = try ImageProcessor.processForVisionAPI(image)
        
        let systemPrompt = """
        You are a nutritional database. Analyze the food in this image and return a JSON object with keys: 
        calories, protein, carbs, fat, and food_name. Use average nutritional values for a typical serving. 
        Return ONLY the JSON, no additional text.
        """
        
        // Build message content with image and optional text context
        var userContent: [[String: Any]] = [
            [
                "type": "text",
                "text": context ?? "Analyze this food image and provide nutritional information."
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
    
    // MARK: - Private Helpers
    
    private func sendRequest(_ requestBody: [String: Any]) async throws -> NutritionResponse {
        let settings = SettingsManager.shared
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.invalidResponse
        }
        
        var request = URLRequest(url: URL(string: proxyURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appSecret, forHTTPHeaderField: "x-app-secret")
        request.httpBody = jsonData
        request.timeoutInterval = 30 // Longer timeout for vision API
        
        // If user provided their own API key, send it
        if let apiKey = settings.openAIApiKey {
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
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let nutritionData = cleanedContent.data(using: .utf8) else {
                throw OpenAIError.invalidResponse
            }
            
            let nutrition = try JSONDecoder().decode(NutritionResponse.self, from: nutritionData)
            
            // Increment request count
            settings.incrementAIRequestCount()
            
            return nutrition
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
}
