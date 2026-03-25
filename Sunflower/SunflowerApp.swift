import SwiftUI
import SwiftData

@main
struct SunflowerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusTag.self,
            FocusSession.self,
            FlowerDrop.self,
            UserSettings.self,
            GardenItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // fallback to in-memory if persistent storage fails
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("Failed to create ModelContainer even with in-memory fallback: \(error.localizedDescription)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
