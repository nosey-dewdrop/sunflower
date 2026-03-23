import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var tag: FocusTag?
    var startedAt: Date
    var duration: Int
    var completed: Bool
    var abandoned: Bool

    init(tag: FocusTag?, startedAt: Date, duration: Int, completed: Bool, abandoned: Bool) {
        self.id = UUID()
        self.tag = tag
        self.startedAt = startedAt
        self.duration = duration
        self.completed = completed
        self.abandoned = abandoned
    }
}
