import AlarmKit
import Foundation

/// Metadata carried into the system AlarmKit alarm UI and the AlarmedWidget
/// Live Activity. Mirrored by an identical struct in the AlarmedWidget target.
@available(iOS 26.0, *)
nonisolated struct AlarmedAlarmMetadata: AlarmMetadata {
    var alarmId: String
    var challengeMode: String
}
