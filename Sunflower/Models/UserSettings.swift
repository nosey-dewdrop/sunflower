import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var pomoDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int
    var pomosBeforeLongBreak: Int
    var weekStartMonday: Bool
    var notificationsEnabled: Bool

    init() {
        self.id = UUID()
        self.pomoDuration = 1500
        self.shortBreakDuration = 300
        self.longBreakDuration = 900
        self.pomosBeforeLongBreak = 4
        self.weekStartMonday = true
        self.notificationsEnabled = true
    }
}
