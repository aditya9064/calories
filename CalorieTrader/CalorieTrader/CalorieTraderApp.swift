import SwiftUI

@main
struct CalorieTraderApp: App {
    @StateObject private var store = CalorieStore()
    @StateObject private var healthKit = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(healthKit)
        }
    }
}
