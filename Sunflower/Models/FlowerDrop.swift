import Foundation
import SwiftData

@Model
final class FlowerDrop {
    var id: UUID
    var flowerType: String
    var positionX: Double
    var positionY: Double
    var earnedAt: Date

    init(flowerType: String, positionX: Double, positionY: Double) {
        self.id = UUID()
        self.flowerType = flowerType
        self.positionX = positionX
        self.positionY = positionY
        self.earnedAt = Date()
    }

    static let flowerTypes = ["sunflower", "daisy", "tulip", "rose", "lavender"]

    static func randomType() -> String {
        flowerTypes.randomElement() ?? "sunflower"
    }
}
