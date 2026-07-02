import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: Int

    // screenshot tooling: -screenshots seeds a demo garden and skips onboarding,
    // -page timer|settings|stats picks the visible screen (app store + landing shots)
    private static let screenshotMode = ProcessInfo.processInfo.arguments.contains("-screenshots")

    init() {
        let args = ProcessInfo.processInfo.arguments
        var tab = 1
        if let i = args.firstIndex(of: "-page"), i + 1 < args.count {
            switch args[i + 1] {
            case "settings": tab = 0
            case "stats": tab = 2
            default: tab = 1
            }
        }
        _selectedTab = State(initialValue: tab)
    }

    var body: some View {
        if hasOnboarded || Self.screenshotMode {
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
