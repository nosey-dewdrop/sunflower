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

    static func randomType() -> String {
        flowerTypes.randomElement() ?? "sunflower"
    }
}
