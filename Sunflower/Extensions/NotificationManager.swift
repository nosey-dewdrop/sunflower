import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleTimerComplete(in seconds: Int, isFocus: Bool) {
        cancelAll()
        let content = UNMutableNotificationContent()
        content.title = isFocus ? "focus complete!" : "break's over!"
        content.body = isFocus ? "you earned a flower" : "time to focus again"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(TimeInterval(seconds), 1), repeats: false)
        let request = UNNotificationRequest(identifier: "timerComplete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
