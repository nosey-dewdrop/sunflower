import Foundation
import SwiftData

@Model
final class FocusTag {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var treePositionX: Double
    var treePositionY: Double

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.tag)
    var sessions: [FocusSession]

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.treePositionX = Double.random(in: 0.15...0.85)
        self.treePositionY = Double.random(in: 0.45...0.75)
        self.sessions = []
    }

    var completedSessions: [FocusSession] {
        sessions.filter { $0.completed }
    }

    var appleCount: Int {
        completedSessions.count
    }

    var totalFocusMinutes: Int {
        completedSessions.reduce(0) { $0 + $1.duration } / 60
    }

    // tree growth: small (0-30min), medium (30-120min), large (120min+)
    var treeSize: String {
        if totalFocusMinutes >= 120 { return "large" }
        if totalFocusMinutes >= 30 { return "medium" }
        return "small"
    }

    var treeSizePoints: CGFloat {
        switch treeSize {
        case "large": return 50
        case "medium": return 38
        default: return 26
        }
    }
}
