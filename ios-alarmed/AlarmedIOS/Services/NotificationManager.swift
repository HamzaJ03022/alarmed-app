import Foundation
import UserNotifications

final class NotificationManager: NSObject, @unchecked Sendable {
    static let shared = NotificationManager()
    private override init() { super.init(); UNUserNotificationCenter.current().delegate = self }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notification permission granted: \(granted)")
            if let completion = completion {
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

    /// Schedules the alarm as time-sensitive notification(s). Returns a
    /// user-readable error, or nil on success.
    func scheduleAlarm(_ alarm: Alarm) async -> String? {
        guard alarm.isActive else { return nil }
        cancelAlarm(id: alarm.id)

        let parts = alarm.time.split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else { return "The alarm time could not be parsed." }

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.body = alarm.dismissalMode == "phrase"
            ? "Wake up! Complete your challenge to dismiss."
            : "Wake up! Answer questions to dismiss."
        // Custom bundled alarm tone in CAF (Apple's documented custom
        // notification-sound format; the original mp3 may be ignored by iOS).
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive

        do {
            if alarm.repeatDays.isEmpty {
                var components = DateComponents()
                components.hour = hours
                components.minute = minutes
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)
                try await UNUserNotificationCenter.current().add(request)
            } else {
            let dayMap: [String: Int] = [
                "sun": 1, "mon": 2, "tue": 3, "wed": 4,
                "thu": 5, "fri": 6, "sat": 7
            ]
            for day in alarm.repeatDays {
                guard let weekday = dayMap[day] else { continue }
                var components = DateComponents()
                components.hour = hours
                components.minute = minutes
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id)-\(day)",
                    content: content,
                    trigger: trigger
                )
                try await UNUserNotificationCenter.current().add(request)
                }
            }
        } catch {
            return error.localizedDescription
        }
        return nil
    }

    func cancelAlarm(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id] + ["sun", "mon", "tue", "wed", "thu", "fri", "sat"].map { "\(id)-\($0)" }
        )
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier.components(separatedBy: "-").first ?? ""
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .alarmTriggered,
                object: nil,
                userInfo: ["alarmId": identifier]
            )
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}
