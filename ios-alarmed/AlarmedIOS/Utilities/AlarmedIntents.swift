import AlarmKit
import AppIntents
import Foundation

/// Pending-ring marker: written whenever the system alarm UI routes into the
/// app (Done or Challenge button). The timestamp lets a stale marker — e.g.
/// one recorded in the morning while the app was already running, discovered
/// at bedtime — be dropped instead of replaying the challenge.
enum AlarmedPendingAlarm {
    static let key = "alarmed_pending_ring_alarm_id"
    static let timestampKey = "alarmed_pending_ring_timestamp"
    /// Markers older than this are leftovers from a challenge that already
    /// finished (or was never started), never a ring the user just tapped.
    static let maxAge: TimeInterval = 120

    static func record(alarmID: String) {
        UserDefaults.standard.set(alarmID, forKey: key)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: timestampKey)
    }

    /// Returns the recorded alarm id only when the marker is fresh, and always
    /// consumes it. A stale (or legacy, timestamp-less) marker is cleared and
    /// returns nil so opening the app later never rings a ghost alarm.
    static func consumeFresh() -> String? {
        guard let id = UserDefaults.standard.string(forKey: key) else { return nil }
        let recorded = UserDefaults.standard.double(forKey: timestampKey)
        let age = recorded > 0 ? Date().timeIntervalSince1970 - recorded : .infinity
        clear()
        return age <= maxAge ? id : nil
    }
}

/// Run by the AlarmKit system alarm UI's Challenge button. Opens Alarmed
/// directly on the ringing screen so the wake-up challenge is always enforced
/// before the alarm is dismissed. The system alarm keeps ringing until the
/// app silences it (or the challenge is solved) — re-ring backups stay armed.
struct OpenChallengeIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Start wake-up challenge"
    static let openAppWhenRun = true

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        AlarmedPendingAlarm.record(alarmID: alarmID)
        NotificationCenter.default.post(name: .alarmTriggered, object: nil, userInfo: ["alarmId": alarmID])
        return .result()
    }
}

/// Run by the Done (stop) button on the AlarmKit system alarm UI. Stops every
/// system ring for this alarm — the main alarm and any re-ring backup that is
/// currently alerting — before opening the challenge screen, so "Done" can
/// never leave the alarm in a half-ringing state that replays later. The
/// challenge is still enforced: Done routes into it like before, and the
/// still-pending future backups keep re-ringing until it is solved.
struct StopAndChallengeIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop alarm and start wake-up challenge"
    static let openAppWhenRun = true

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        if #available(iOS 26.0, *) {
            var related = Set(AlarmBackupIds.ids(for: alarmID))
            if let parent = UUID(uuidString: alarmID) { related.insert(parent) }
            if let current = try? AlarmManager.shared.alarms {
                for systemAlarm in current where related.contains(systemAlarm.id) && systemAlarm.state == .alerting {
                    try? await AlarmManager.shared.stop(id: systemAlarm.id)
                }
            }
        }
        AlarmedPendingAlarm.record(alarmID: alarmID)
        NotificationCenter.default.post(name: .alarmTriggered, object: nil, userInfo: ["alarmId": alarmID])
        return .result()
    }
}
