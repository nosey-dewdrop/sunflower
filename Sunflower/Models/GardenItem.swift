import Foundation
import SwiftData

@Model
final class GardenItem {
    var id: UUID
    var itemType: String    // "oak", "pine", "cherry", "birch", "sunflower", "daisy", "tulip", "rose", "lavender", "fence", "rock", "pond"
    var category: String    // "tree", "flower", "decoration"
    var positionX: Double
    var positionY: Double
    var linkedTagId: UUID?  // if tree, linked to a goal/tag
    var placedAt: Date

    init(itemType: String, category: String, positionX: Double, positionY: Double, linkedTagId: UUID? = nil) {
        self.id = UUID()
        self.itemType = itemType
        self.category = category
        self.positionX = positionX
        self.positionY = positionY
        self.linkedTagId = linkedTagId
        self.placedAt = Date()
    }

    var displaySize: CGFloat {
        switch category {
        case "tree": return 50
        case "flower": return 24
        default: return 30
        }
    }
}
