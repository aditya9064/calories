import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            FoodLogView()
                .tabItem {
                    Label("Log Food", systemImage: "camera.fill")
                }
                .tag(1)

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.tradeGreen)
        .preferredColorScheme(.dark)
        .task {
            await healthKit.requestAuthorization()
            healthKit.startLiveObserver()
        }
    }
}
