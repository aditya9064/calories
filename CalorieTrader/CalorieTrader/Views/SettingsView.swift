import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var healthKit: HealthKitManager
    @AppStorage("anthropic_api_key") private var apiKey = ""
    @State private var goalText = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.tradeDark.ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            Label("HealthKit", systemImage: "heart.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text(healthKit.isAuthorized ? "Connected" : "Not Connected")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(healthKit.isAuthorized ? .tradeGreen : .tradeRed)
                        }

                        if !healthKit.isAuthorized {
                            Button("Connect to Apple Health") {
                                Task { await healthKit.requestAuthorization() }
                            }
                            .foregroundColor(.tradeGreen)
                        }

                        Button("Refresh Health Data") {
                            Task { await healthKit.fetchTodayData() }
                        }
                        .foregroundColor(.tradeBlue)
                    } header: {
                        sectionHeader("APPLE HEALTH")
                    }
                    .listRowBackground(Color.tradePanel)

                    Section {
                        HStack {
                            Text("Calorie Goal")
                                .foregroundColor(.white)
                            Spacer()
                            TextField("2000", text: $goalText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.tradeGreen)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(width: 80)
                                .onAppear { goalText = String(Int(store.calorieGoal)) }
                                .onChange(of: goalText) { val in
                                    if let g = Double(val) { store.calorieGoal = g }
                                }
                        }
                    } header: {
                        sectionHeader("GOALS")
                    }
                    .listRowBackground(Color.tradePanel)

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anthropic API Key")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                            SecureField("sk-ant-...", text: $apiKey)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.tradeGreen)
                            Text("Required for AI food analysis. Get yours at console.anthropic.com")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        sectionHeader("AI FOOD ANALYSIS")
                    }
                    .listRowBackground(Color.tradePanel)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            statRow("BMR", value: String(format: "%.0f kcal", healthKit.bmr))
                            statRow("Active Calories", value: String(format: "%.0f kcal", healthKit.activeCaloriesToday))
                            statRow("Steps Today", value: String(format: "%.0f", healthKit.stepCount))
                            statRow("Workouts Today", value: "\(healthKit.workouts.count)")
                        }
                    } header: {
                        sectionHeader("TODAY'S STATS")
                    }
                    .listRowBackground(Color.tradePanel)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.tradeGreen)
        }
        .padding(.vertical, 2)
    }
}
