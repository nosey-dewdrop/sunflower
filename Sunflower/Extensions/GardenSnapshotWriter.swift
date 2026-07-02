import Foundation
import SwiftData
import WidgetKit

enum GardenSnapshotWriter {
    static func refresh(context: ModelContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        let allFlowers = (try? context.fetch(FetchDescriptor<FlowerDrop>())) ?? []
        let todayFlowers = allFlowers
            .filter { $0.earnedAt >= todayStart }
            .sorted { $0.earnedAt < $1.earnedAt }
            .suffix(FlowerDrop.maxVisible)
            .map { SnapshotFlower(type: $0.flowerType, x: $0.positionX, y: $0.positionY, size: Double($0.displaySize)) }

        let completed = ((try? context.fetch(FetchDescriptor<FocusSession>())) ?? []).filter { $0.completed }
        let daysWithFocus = Set(completed.map { calendar.startOfDay(for: $0.startedAt) })

        // streak survives until today's first session lands
        var streak = 0
        var day = todayStart
        if !daysWithFocus.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while daysWithFocus.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }

        let todayMinutes = completed
            .filter { $0.startedAt >= todayStart }
            .reduce(0) { $0 + $1.duration / 60 }

        GardenSnapshot(flowers: todayFlowers, streak: streak, todayMinutes: todayMinutes).save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
