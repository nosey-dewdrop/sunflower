import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var pomoDuration: Int
    var weekStartMonday: Bool
    var notificationsEnabled: Bool

    init() {
        self.id = UUID()
        self.pomoDuration = 1200
        self.weekStartMonday = true
        self.notificationsEnabled = true
    }
}
