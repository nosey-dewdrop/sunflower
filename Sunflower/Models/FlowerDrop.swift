import Foundation
import SwiftData

@Model
final class FlowerDrop {
    var id: UUID
    var flowerType: String
    var size: String // "small", "medium", "large"
    var positionX: Double
    var positionY: Double
    var earnedAt: Date

    init(flowerType: String, size: String, positionX: Double, positionY: Double) {
        self.id = UUID()
        self.flowerType = flowerType
        self.size = size
        self.positionX = positionX
        self.positionY = positionY
        self.earnedAt = Date()
    }

    // short sessions grow little daisies, 60 min grows them up, 90 min blooms big
    static func sizeForDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 90 { return "large" }
        if minutes >= 60 { return "medium" }
        return "small"
    }

    static func typeForDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 90 { return ["sunflower", "lavender"].randomElement() ?? "sunflower" }
        if minutes >= 60 { return ["tulip", "rose"].randomElement() ?? "tulip" }
        return "daisy"
    }

    // MARK: - Garden slots

    // the garden is one screen, never scrolls: 12 fixed slots that dodge the timer ui,
    // a new bloom takes the oldest slot so the screen never holds more than 12 flowers
    static let maxVisible = 12

    static let gardenSlots: [(x: Double, y: Double)] = [
        (0.15, 0.13), (0.50, 0.09), (0.85, 0.14),
        (0.11, 0.30), (0.89, 0.32),
        (0.09, 0.52), (0.91, 0.55),
        (0.18, 0.70), (0.45, 0.67), (0.76, 0.72),
        (0.30, 0.86), (0.66, 0.88)
    ]

    static func slotPosition(forTodayCount count: Int) -> (x: Double, y: Double) {
        let slot = gardenSlots[count % gardenSlots.count]
        let jitterX = Double.random(in: -0.02...0.02)
        let jitterY = Double.random(in: -0.015...0.015)
        return (min(0.95, max(0.05, slot.x + jitterX)), min(0.92, max(0.06, slot.y + jitterY)))
    }

    var displaySize: CGFloat {
        switch size {
        case "large": return 32
        case "medium": return 24
        default: return 16
        }
    }

    // all flower types are free; pro sells power, not petals
    static let flowerTypes = ["sunflower", "daisy", "tulip", "rose", "lavender"]

    static func randomType() -> String {
        flowerTypes.randomElement() ?? "sunflower"
    }

    // tag color dots are drawn as doodle flowers; map each tag hex to the closest flower asset
    static func assetForTagColor(_ hex: String) -> String {
        switch hex.uppercased() {
        case "F4D35E", "FFEAA7": return "flower_yellow"
        case "FF6B6B", "FF8C69": return "flower_red"
        case "4ECDC4", "45B7D1", "96CEB4": return "flower_blue"
        case "DDA0DD": return "flower_purple"
        default: return "flower_yellow"
        }
    }
}
