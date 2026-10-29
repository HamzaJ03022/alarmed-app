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

    /// Ground-truth lines for the Settings diagnostics card: build number,
    /// embedded permission text, bundled tone (plus permission state when the
    /// scheduler exposes it).
    func groundTruthLines() -> [String]

    /// Raw permission state reported by the system, when exposed.
    func rawPermissionStateLine() -> String?

    /// The wake-up challenge was solved: silence anything still ringing for
    /// this alarm, clear its re-ring backups, and (for repeating alarms) arm
    /// fresh backups for the next occurrence.
    func challengeSolved(_ alarm: Alarm) async

    /// Stops a system alert that is ringing while the in-app challenge is on
    /// screen and already playing the alarm tone itself.
    func silenceSystemAlert(systemId: String) async

    /// Maps each active alarm id to how many of its re-ring backups are
    /// currently armed, or nil when the scheduler cannot enumerate them.
    func armedBackupCounts(alarms: [Alarm]) async -> [String: Int]?
}

extension AlarmScheduling {
    func reconcile(alarms: [Alarm]) async {}

    func runDiagnostics() async -> String {
        "The alarm engine check runs on iOS 26 and later."
    }

    func groundTruthLines() -> [String] {
        AlarmBundleFacts.lines
    }

    func rawPermissionStateLine() -> String? { nil }

    func challengeSolved(_ alarm: Alarm) async {}

    func silenceSystemAlert(systemId: String) async {}

    func armedBackupCounts(alarms: [Alarm]) async -> [String: Int]? { nil }
}

/// Deterministic IDs for the re-ring backups that follow every alarm. Each
/// backup ID is the alarm's UUID with its last byte XOR-ed by the backup
/// index, so backups can be found, cancelled and mapped back to their alarm
/// without storing anything.
enum AlarmBackupIds {
    /// Backup rings per alarm — one per minute after the alarm time.
    static let count = 15

    static func ids(for alarmId: String) -> [UUID] {
        guard let base = UUID(uuidString: alarmId) else { return [] }
        return (1...count).map { index in
            var bytes = base.uuid
            bytes.15 ^= UInt8(index)
            return UUID(uuid: bytes)
        }
    }

    /// Resolves a system alarm ID (the alarm itself or one of its backups)
    /// to the app alarm it belongs to.
    static func parentAlarmId(for systemId: String, among alarms: [Alarm]) -> String? {
        if alarms.contains(where: { $0.id == systemId }) { return systemId }
        guard let uuid = UUID(uuidString: systemId) else { return nil }
        return alarms.first(where: { ids(for: $0.id).contains(uuid) })?.id
    }

    /// Next time the alarm will fire strictly after `date`, honoring its
    /// repeat days. Used to anchor the backup rings.
    static func nextOccurrence(of alarm: Alarm, after date: Date) -> Date? {
        let parts = alarm.time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute) else {
            return nil
        }
        let weekdayNumbers: [String: Int] = [
            "sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7
        ]
        let allowed = Set(alarm.repeatDays.compactMap { weekdayNumbers[$0] })
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        for dayOffset in 0...8 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                  let candidate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  candidate > date else { continue }
            if allowed.isEmpty || allowed.contains(calendar.component(.weekday, from: candidate)) {
                return candidate
            }
        }
        return nil
    }
}

/// Facts about the installed bundle that disambiguate any future diagnostic
/// screenshot: which build is installed and whether the two critical
/// resources (permission text, alarm tone) actually shipped in it.
enum AlarmBundleFacts {
    static var lines: [String] {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        var lines = ["App version \(version), build \(build)"]
        if Bundle.main.object(forInfoDictionaryKey: "NSAlarmKitUsageDescription") != nil {
            lines.append("Alarm permission text embedded: yes")
        } else {
            lines.append("Alarm permission text embedded: NO — this build cannot register system alarms")
        }
        lines.append(AlarmSoundTester.isToneBundled
            ? "Loud alarm tone bundled: yes"
            : "Loud alarm tone bundled: NO — alarms would use the quiet default tone")
        let bundled = AlarmSound.all.filter(\.isBundled).count
        lines.append("Alarm sound library: \(bundled) of \(AlarmSound.all.count) tones bundled")
        lines.append(contentsOf: CrashGuard.diagnosticLines)
        return lines
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
