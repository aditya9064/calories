import Foundation
import Combine

@MainActor
class CalorieStore: ObservableObject {
    @Published var foodEntries: [FoodEntry] = []
    @Published var manualWorkouts: [WorkoutEntry] = []
    @Published var calorieGoal: Double = 2000

    private let foodKey = "food_entries"
    private let workoutKey = "manual_workouts"
    private let goalKey = "calorie_goal"

    init() {
        load()
    }

    // MARK: - Food

    func addFood(_ entry: FoodEntry) {
        foodEntries.append(entry)
        save()
    }

    func removeFood(at offsets: IndexSet) {
        foodEntries.remove(atOffsets: offsets)
        save()
    }

    func todayFood() -> [FoodEntry] {
        let start = Calendar.current.startOfDay(for: Date())
        return foodEntries.filter { $0.timestamp >= start }
    }

    func food(for date: Date) -> [FoodEntry] {
        let start = Calendar.current.startOfDay(for: date)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return foodEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    func totalCaloriesConsumed(for date: Date) -> Double {
        food(for: date).reduce(0) { $0 + $1.calories }
    }

    // MARK: - Summaries

    func daySummaries(for period: SummaryPeriod, healthKit: HealthKitManager) -> [DaySummary] {
        let calendar = Calendar.current
        let today = Date()
        let days: Int

        switch period {
        case .day: days = 1
        case .week: days = 7
        case .month: days = 30
        }

        return (0..<days).compactMap { offset -> DaySummary? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let consumed = totalCaloriesConsumed(for: date)
            let burned = offset == 0 ? healthKit.activeCaloriesToday : 0
            let bmr = healthKit.bmr
            return DaySummary(date: date, caloriesConsumed: consumed,
                              caloriesBurned: burned, bmr: bmr)
        }.reversed()
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: foodKey),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            foodEntries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: workoutKey),
           let decoded = try? JSONDecoder().decode([WorkoutEntry].self, from: data) {
            manualWorkouts = decoded
        }
        calorieGoal = UserDefaults.standard.double(forKey: goalKey)
        if calorieGoal == 0 { calorieGoal = 2000 }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(foodEntries) {
            UserDefaults.standard.set(data, forKey: foodKey)
        }
        if let data = try? JSONEncoder().encode(manualWorkouts) {
            UserDefaults.standard.set(data, forKey: workoutKey)
        }
        UserDefaults.standard.set(calorieGoal, forKey: goalKey)
    }
}
