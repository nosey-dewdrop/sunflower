import Foundation

// lightweight snapshot shared with the widget through the app group;
// the widget never touches swiftdata, it just reads this
struct SnapshotFlower: Codable {
    let type: String
    let x: Double
    let y: Double
    let size: Double
}

struct GardenSnapshot: Codable {
    var flowers: [SnapshotFlower]
    var streak: Int
    var todayMinutes: Int

    static let suiteName = "group.com.noseyDewdrop.sunflower"
    static let key = "gardenSnapshot"

    static func load() -> GardenSnapshot {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(GardenSnapshot.self, from: data) else {
            return GardenSnapshot(flowers: [], streak: 0, todayMinutes: 0)
        }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.suiteName)?.set(data, forKey: Self.key)
    }
}
