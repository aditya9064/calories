import Foundation
import SwiftUI

// MARK: - Core Models

struct FoodEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var timestamp: Date
    var imageData: Data?

    init(id: UUID = UUID(), name: String, calories: Double,
         protein: Double = 0, carbs: Double = 0, fat: Double = 0,
         timestamp: Date = Date(), imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.imageData = imageData
    }
}

struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var caloriesBurned: Double
    var duration: TimeInterval
    var timestamp: Date

    init(id: UUID = UUID(), name: String, caloriesBurned: Double,
         duration: TimeInterval, timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.caloriesBurned = caloriesBurned
        self.duration = duration
        self.timestamp = timestamp
    }
}

struct DaySummary: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let caloriesConsumed: Double
    let caloriesBurned: Double
    let bmr: Double

    var netCalories: Double { caloriesConsumed - caloriesBurned - bmr }
    var isSurplus: Bool { netCalories > 0 }

    var changePercent: Double {
        let base = bmr + caloriesBurned
        guard base > 0 else { return 0 }
        return (netCalories / base) * 100
    }
}

struct FoodAnalysisResult {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double
    let breakdown: [String: Double]
}

// MARK: - Period Enum

enum SummaryPeriod: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
}
