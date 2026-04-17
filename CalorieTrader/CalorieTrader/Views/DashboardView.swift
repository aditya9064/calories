import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var healthKit: HealthKitManager

    private var consumed: Double { store.todayFood().reduce(0) { $0 + $1.calories } }
    private var burned: Double { healthKit.activeCaloriesToday }
    private var bmr: Double { healthKit.bmr }
    private var net: Double { consumed - burned - bmr }
    private var isSurplus: Bool { net > 0 }

    private var primaryColor: Color { isSurplus ? .tradeGreen : .tradeRed }
    private var changePercent: Double {
        let base = burned + bmr
        guard base > 0 else { return 0 }
        return (net / base) * 100
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.tradeDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerTicker
                        mainCard
                        metricsRow
                        workoutsCard
                        recentFoodCard
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header Ticker

    private var headerTicker: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CALORIE TRACKER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
                Text("Today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .opacity(healthKit.isAuthorized ? 1 : 0.3)
                Text(healthKit.isAuthorized ? "LIVE" : "OFFLINE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(healthKit.isAuthorized ? .tradeGreen : .gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.tradePanel)
            .cornerRadius(4)
        }
    }

    // MARK: - Main Card

    private var mainCard: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NET CALORIES")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(isSurplus ? "+" : "")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryColor)
                        Text(String(format: "%.0f", abs(net)))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryColor)
                        Text("kcal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(primaryColor.opacity(0.7))
                            .padding(.bottom, 6)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("VS GOAL")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                    changeTag
                }
            }
            MiniSparkline(net: net, isSurplus: isSurplus)
                .frame(height: 60)
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(primaryColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var changeTag: some View {
        HStack(spacing: 2) {
            Image(systemName: isSurplus ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12, weight: .bold))
            Text(String(format: "%.1f%%", abs(changePercent)))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .foregroundColor(primaryColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(primaryColor.opacity(0.15))
        .cornerRadius(6)
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: 12) {
            MetricTile(label: "CONSUMED", value: consumed, unit: "kcal", color: .white)
            MetricTile(label: "BURNED", value: burned + bmr, unit: "kcal", color: .tradeBlue)
            MetricTile(label: "STEPS", value: healthKit.stepCount, unit: "steps", color: .tradeYellow)
        }
    }

    // MARK: - Workouts Card

    private var workoutsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "WORKOUTS", subtitle: "Today")
            if healthKit.workouts.isEmpty {
                Text("No workouts logged today")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(healthKit.workouts) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }

    // MARK: - Recent Food

    private var recentFoodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "RECENT FOOD", subtitle: "Today")
            let todayFood = store.todayFood()
            if todayFood.isEmpty {
                Text("No food logged today")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(todayFood.suffix(3).reversed()) { entry in
                    FoodRow(entry: entry)
                }
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.7))
        }
    }
}

// MARK: - Supporting Components

struct MetricTile: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(String(format: "%.0f", value))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.tradePanel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct WorkoutRow: View {
    let workout: WorkoutEntry

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.tradeRed)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(String(format: "%.0f min", workout.duration / 60))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(String(format: "-%.0f kcal", workout.caloriesBurned))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.tradeRed)
        }
        .padding(.vertical, 4)
    }
}

struct FoodRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            Image(systemName: "fork.knife")
                .foregroundColor(.tradeGreen)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(String(format: "+%.0f kcal", entry.calories))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.tradeGreen)
        }
        .padding(.vertical, 4)
    }
}

struct MiniSparkline: View {
    let net: Double
    let isSurplus: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .cornerRadius(4)

                let barHeight = min(abs(net) / 500 * geo.size.height, geo.size.height)
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            isSurplus ? Color.tradeGreen.opacity(0.8) : Color.tradeRed.opacity(0.8),
                            isSurplus ? Color.tradeGreen.opacity(0.1) : Color.tradeRed.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: barHeight)
                    .cornerRadius(4)
            }
        }
    }
}
