import AppIntents
import Foundation

enum AlarmedPendingAlarm {
    static let key = "alarmed_pending_ring_alarm_id"
}

/// Run by the AlarmKit system alarm UI (Stop and Challenge buttons). Opens
/// Alarmed directly on the ringing screen so the wake-up challenge is always
/// enforced before the alarm is dismissed.
struct OpenChallengeIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Start wake-up challenge"
    static let openAppWhenRun = true

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(alarmID, forKey: AlarmedPendingAlarm.key)
        NotificationCenter.default.post(name: .alarmTriggered, object: nil, userInfo: ["alarmId": alarmID])
        return .result()
    }
}
