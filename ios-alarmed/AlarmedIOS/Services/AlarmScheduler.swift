import Foundation

/// Abstracts alarm scheduling so the app can use AlarmKit (system alarms that
/// break through Silent mode and Focus) on iOS 26+, with time-sensitive local
/// notifications as the fallback on older systems or when AlarmKit fails.
protocol AlarmScheduling {
    func schedule(_ alarm: Alarm)
    func cancel(id: String)
}

/// Fallback scheduler backed by time-sensitive notifications.
struct NotificationScheduler: AlarmScheduling {
    func schedule(_ alarm: Alarm) {
        NotificationManager.shared.scheduleAlarm(alarm)
    }

    func cancel(id: String) {
        NotificationManager.shared.cancelAlarm(id: id)
    }
}

enum AlarmSchedulerFactory {
    static func makeScheduler() -> AlarmScheduling {
        if #available(iOS 26.0, *) {
            return AlarmKitScheduler()
        }
        return NotificationScheduler()
    }
}
