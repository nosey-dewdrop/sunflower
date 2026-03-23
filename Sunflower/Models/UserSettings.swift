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
        self.pomoDuration = 1500
        self.weekStartMonday = true
        self.notificationsEnabled = true
    }
}
