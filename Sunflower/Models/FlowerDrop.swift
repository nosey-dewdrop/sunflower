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

    // <15 min = small, 15-30 min = medium, >30 min = large
    static func sizeForDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 30 { return "large" }
        if minutes >= 15 { return "medium" }
        return "small"
    }

    var displaySize: CGFloat {
        switch size {
        case "large": return 32
        case "medium": return 24
        default: return 16
        }
    }

    static let flowerTypes = ["sunflower", "daisy", "tulip", "rose", "lavender"]
    static let freeFlowerTypes = ["sunflower", "daisy"]

    static func randomType(isPro: Bool = true) -> String {
        (isPro ? flowerTypes : freeFlowerTypes).randomElement() ?? "sunflower"
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
