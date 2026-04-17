import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    @Published var caloriesBurnedToday: Double = 0
    @Published var activeCaloriesToday: Double = 0
    @Published var bmr: Double = 1800
    @Published var workouts: [WorkoutEntry] = []
    @Published var isAuthorized: Bool = false
    @Published var stepCount: Double = 0

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let active = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(active) }
        if let basal = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) { types.insert(basal) }
        if let dietary = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(dietary) }
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
        } catch {
            print("HealthKit auth error: \(error)")
        }
    }

    func fetchTodayData() async {
        async let active = fetchActiveCalories()
        async let basal = fetchBasalCalories()
        async let steps = fetchSteps()
        async let workoutList = fetchWorkouts()

        let (a, b, s, w) = await (active, basal, steps, workoutList)
        activeCaloriesToday = a
        bmr = b > 0 ? b : 1800
        caloriesBurnedToday = a + (b > 0 ? b : 1800)
        stepCount = s
        workouts = w
    }

    private func fetchActiveCalories() async -> Double {
        await fetchQuantity(identifier: .activeEnergyBurned, unit: .kilocalorie())
    }

    private func fetchBasalCalories() async -> Double {
        await fetchQuantity(identifier: .basalEnergyBurned, unit: .kilocalorie())
    }

    private func fetchSteps() async -> Double {
        await fetchQuantity(identifier: .stepCount, unit: .count())
    }

    private func fetchQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchWorkouts() async -> [WorkoutEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                      predicate: predicate,
                                      limit: 20,
                                      sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let entries = (samples as? [HKWorkout] ?? []).map { workout in
                    WorkoutEntry(
                        name: workout.workoutActivityType.name,
                        caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        duration: workout.duration,
                        timestamp: workout.startDate
                    )
                }
                continuation.resume(returning: entries)
            }
            store.execute(query)
        }
    }

    func startLiveObserver() {
        guard let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let query = HKObserverQuery(sampleType: activeType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { await self?.fetchTodayData() }
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: activeType, frequency: .immediate) { _, _ in }
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        default: return "Workout"
        }
    }
}
