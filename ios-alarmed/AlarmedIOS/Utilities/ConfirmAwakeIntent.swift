import AlarmKit
import AppIntents
import Foundation

/// Run by the "I'm awake" button on a wake-up check-in follow-up alarm's
/// system UI. This is the ONLY thing on the follow-up alarm that counts as
/// confirming: it marks the check-in confirmed, stops the ring going off now,
/// and cancels every remaining follow-up ring before returning. Silencing
/// with the side button never reaches this intent.
struct ConfirmAwakeIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "I'm awake"
    /// Runs in the background: no app open, no unlock required.
    static let openAppWhenRun = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        // Await the whole cancellation: the intent must not finish while a
        // scheduled follow-up ring is still pending.
        await WakeUpCheckInStore.shared.confirm(alarmId: alarmID)
        return .result()
    }
}
