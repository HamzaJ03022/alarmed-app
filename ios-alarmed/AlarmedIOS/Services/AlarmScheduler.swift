import Foundation

/// Abstracts alarm scheduling so the app can use AlarmKit (system alarms that
/// break through Silent mode and Focus) on iOS 26+, with time-sensitive
/// notifications as the fallback on older systems or when AlarmKit fails.
protocol AlarmScheduling {
    /// Schedules the alarm if active. Returns a diagnostic result instead of
    /// throwing, so scheduling failures can be surfaced in the UI rather than
    /// failing silently.
    func schedule(_ alarm: Alarm) async -> AlarmScheduleResult

    /// Cancels any scheduled system alarm and notification fallback for the id.
    func cancel(id: String) async

    /// Number of alarms currently registered with the system scheduler, or nil
    /// when the underlying system does not expose them (notifications).
    func registeredSystemAlarmCount() async -> Int?

    /// Re-registers active alarms that are missing from the system scheduler
    /// (e.g. after an app update or reboot). No-op for schedulers that cannot
    /// enumerate their registrations.
    func reconcile(alarms: [Alarm]) async

    /// Registers a throwaway test alarm to report exactly what the system
    /// accepts and rejects. Used by the Settings "Run AlarmKit check" button.
    func runDiagnostics() async -> String
}

extension AlarmScheduling {
    func reconcile(alarms: [Alarm]) async {}

    func runDiagnostics() async -> String {
        "The alarm engine check runs on iOS 26 and later."
    }
}

/// Outcome of one scheduling attempt, used for the Settings diagnostics.
struct AlarmScheduleResult {
    var alarmKitError: String?
    var fallbackError: String?
    var usedAlarmKit: Bool
    /// Full multi-line registration report (levels tried, real error codes).
    var detail: String? = nil

    var isSuccess: Bool { alarmKitError == nil && fallbackError == nil }
}

/// Fallback scheduler backed by time-sensitive notifications.
struct NotificationScheduler: AlarmScheduling {
    func schedule(_ alarm: Alarm) async -> AlarmScheduleResult {
        guard alarm.isActive else {
            return AlarmScheduleResult(alarmKitError: nil, fallbackError: nil, usedAlarmKit: false)
        }
        let error = await NotificationManager.shared.scheduleAlarm(alarm)
        return AlarmScheduleResult(alarmKitError: nil, fallbackError: error, usedAlarmKit: false)
    }

    func cancel(id: String) {
        NotificationManager.shared.cancelAlarm(id: id)
    }

    func registeredSystemAlarmCount() async -> Int? { nil }
}

enum AlarmSchedulerFactory {
    static func makeScheduler() -> AlarmScheduling {
        if #available(iOS 26.0, *) {
            return AlarmKitScheduler()
        }
        return NotificationScheduler()
    }
}
