import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let timerCompleteId = "timerComplete"
    private let wiltWarningId = "wiltWarning"

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleTimerComplete(in seconds: Int, isFocus: Bool) {
        cancelTimerComplete()
        let content = UNMutableNotificationContent()
        content.title = isFocus ? "focus complete!" : "break's over!"
        content.body = isFocus ? "a flower bloomed in your garden" : "time to focus again"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(TimeInterval(seconds), 1), repeats: false)
        let request = UNNotificationRequest(identifier: timerCompleteId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // fires right after leaving the app mid-focus; the gentle pull back
    func scheduleWiltWarning() {
        cancelWiltWarning()
        let content = UNMutableNotificationContent()
        content.title = "your flower is wilting"
        content.body = "come back before it droops for good"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: wiltWarningId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelTimerComplete() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerCompleteId])
    }

    func cancelWiltWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [wiltWarningId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [wiltWarningId])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
