import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: Int = 1

    var body: some View {
        if hasOnboarded {
            TabView(selection: $selectedTab) {
                SettingsView()
                    .tag(0)

                TimerView()
                    .tag(1)

                StatsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        } else {
            OnboardingView(hasOnboarded: $hasOnboarded)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FocusTag.self, FocusSession.self, FlowerDrop.self, UserSettings.self, GardenItem.self], inMemory: true)
}
