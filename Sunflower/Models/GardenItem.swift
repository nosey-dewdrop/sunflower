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

// MARK: - Shop Catalog

struct ShopItem: Identifiable {
    let id = UUID()
    let itemType: String
    let category: String
    let name: String
    let price: Int
    let icon: String

    static let catalog: [ShopItem] = [
        // Trees
        ShopItem(itemType: "oak", category: "tree", name: "Oak", price: 10, icon: "tree.fill"),
        ShopItem(itemType: "pine", category: "tree", name: "Pine", price: 10, icon: "tree.fill"),
        ShopItem(itemType: "cherry", category: "tree", name: "Cherry", price: 15, icon: "tree.fill"),
        ShopItem(itemType: "birch", category: "tree", name: "Birch", price: 12, icon: "tree.fill"),

        // Flowers
        ShopItem(itemType: "sunflower", category: "flower", name: "Sunflower", price: 3, icon: "sun.max.fill"),
        ShopItem(itemType: "daisy", category: "flower", name: "Daisy", price: 3, icon: "sparkle"),
        ShopItem(itemType: "tulip", category: "flower", name: "Tulip", price: 3, icon: "leaf.fill"),
        ShopItem(itemType: "rose", category: "flower", name: "Rose", price: 5, icon: "heart.fill"),
        ShopItem(itemType: "lavender", category: "flower", name: "Lavender", price: 4, icon: "star.fill"),

    ]

    static func forCategory(_ cat: String) -> [ShopItem] {
        catalog.filter { $0.category == cat }
    }
}
