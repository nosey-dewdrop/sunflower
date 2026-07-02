import ActivityKit
import Foundation

enum LiveActivityManager {
    static func start(flowerType: String, endDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()
        let attributes = FocusActivityAttributes(flowerType: flowerType)
        let state = FocusActivityAttributes.ContentState(endDate: endDate)
        _ = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: endDate)
        )
    }

    static func end() {
        Task {
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
