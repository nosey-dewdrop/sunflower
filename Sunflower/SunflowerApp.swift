import SwiftUI
import SwiftData

@main
struct SunflowerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusTag.self,
            FocusSession.self,
            FlowerDrop.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
