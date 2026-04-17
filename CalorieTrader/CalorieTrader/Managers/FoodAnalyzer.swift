import Foundation
import UIKit

class FoodAnalyzer {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"

    init(apiKey: String = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    func analyze(image: UIImage) async throws -> FoodAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodAnalyzerError.imageEncodingFailed
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analyze this food image and return ONLY a JSON object with no markdown formatting:
                            {
                              "name": "dish name",
                              "total_calories": 0,
                              "protein_g": 0,
                              "carbs_g": 0,
                              "fat_g": 0,
                              "confidence": 0.0,
                              "breakdown": {"item1": calories1, "item2": calories2}
                            }
                            Estimate calories accurately. Confidence 0-1. Return only raw JSON.
                            """
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FoodAnalyzerError.apiError
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = decoded.content.first?.text else {
            throw FoodAnalyzerError.parseError
        }

        return try parseResult(from: text)
    }

    private func parseResult(from text: String) throws -> FoodAnalysisResult {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw FoodAnalyzerError.parseError
        }

        let breakdown = json["breakdown"] as? [String: Double] ?? [:]

        return FoodAnalysisResult(
            name: json["name"] as? String ?? "Unknown Food",
            calories: json["total_calories"] as? Double ?? 0,
            protein: json["protein_g"] as? Double ?? 0,
            carbs: json["carbs_g"] as? Double ?? 0,
            fat: json["fat_g"] as? Double ?? 0,
            confidence: json["confidence"] as? Double ?? 0.8,
            breakdown: breakdown
        )
    }
}

// MARK: - Response Models

private struct AnthropicResponse: Decodable {
    let content: [ContentBlock]
}

private struct ContentBlock: Decodable {
    let text: String
}

// MARK: - Errors

enum FoodAnalyzerError: LocalizedError {
    case imageEncodingFailed
    case apiError
    case parseError
    case noApiKey

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed: return "Failed to encode image"
        case .apiError: return "API request failed"
        case .parseError: return "Failed to parse response"
        case .noApiKey: return "No API key configured"
        }
    }
}
