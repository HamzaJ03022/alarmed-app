import ActivityKit
import AlarmKit
import Foundation
import os
import SwiftUI

enum AlarmScheduleError: LocalizedError {
    case notAuthorized
    case invalidTime

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Alarm permission was not granted."
        case .invalidTime: return "The alarm time could not be parsed."
        }
    }
}

/// Schedules alarms with AlarmKit on iOS 26+. Falls back to time-sensitive
/// notifications per alarm if AlarmKit authorization or scheduling fails.
@available(iOS 26.0, *)
struct AlarmKitScheduler: AlarmScheduling {
    /// Disambiguates from the app's own `Alarm` model struct.
    private typealias SystemAlarm = AlarmKit.Alarm

    private static let logger = Logger(subsystem: "com.nyytech.alarmed", category: "AlarmKit")

    func schedule(_ alarm: Alarm) async -> AlarmScheduleResult {
        guard alarm.isActive else {
            return AlarmScheduleResult(alarmKitError: nil, fallbackError: nil, usedAlarmKit: false)
        }
        let kitId = UUID(uuidString: alarm.id) ?? UUID()
        do {
            try await Self.scheduleWithAlarmKit(alarm, id: kitId)
            Self.logger.info("AlarmKit alarm registered (id: \(alarm.id, privacy: .public), time: \(alarm.time, privacy: .public))")
            return AlarmScheduleResult(alarmKitError: nil, fallbackError: nil, usedAlarmKit: true)
        } catch {
            Self.logger.error("AlarmKit scheduling failed (id: \(alarm.id, privacy: .public)): \(error.localizedDescription, privacy: .public)")
            let fallbackError = await NotificationManager.shared.scheduleAlarm(alarm)
            return AlarmScheduleResult(
                alarmKitError: error.localizedDescription,
                fallbackError: fallbackError,
                usedAlarmKit: false
            )
        }
    }

    func cancel(id: String) async {
        // Cancel both systems: the alarm may have been scheduled as a
        // notification fallback before (e.g. permission denied earlier).
        NotificationManager.shared.cancelAlarm(id: id)
        let uuid = UUID(uuidString: id) ?? UUID()
        try? await AlarmManager.shared.cancel(id: uuid)
    }

    func registeredSystemAlarmCount() async -> Int? {
        (try? AlarmManager.shared.alarms)?.count
    }

    private static func scheduleWithAlarmKit(_ alarm: Alarm, id: UUID) async throws {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { throw AlarmScheduleError.notAuthorized }
        case .authorized:
            break
        case .denied:
            throw AlarmScheduleError.notAuthorized
        @unknown default:
            throw AlarmScheduleError.notAuthorized
        }

        let parts = alarm.time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute) else {
            throw AlarmScheduleError.invalidTime
        }

        let weekdayMap: [String: Locale.Weekday] = [
            "sun": .sunday, "mon": .monday, "tue": .tuesday, "wed": .wednesday,
            "thu": .thursday, "fri": .friday, "sat": .saturday
        ]
        let weekdays = alarm.repeatDays.compactMap { weekdayMap[$0] }

        let schedule: SystemAlarm.Schedule
        if weekdays.isEmpty {
            // One-time alarms fire at an exact pre-computed date. Fixed-date
            // one-shots are what shipping AlarmKit apps register; they remove
            // any dependence on relative-schedule resolution on the device.
            guard let fireDate = TimeFormatter.getNextAlarmTime(time: alarm.time, repeatDays: []) else {
                throw AlarmScheduleError.invalidTime
            }
            schedule = .fixed(fireDate)
        } else {
            let recurrence: SystemAlarm.Schedule.Relative.Recurrence = .weekly(weekdays)
            schedule = SystemAlarm.Schedule.relative(.init(
                time: .init(hour: hour, minute: minute),
                repeats: recurrence
            ))
        }

        let title = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Wake up!" : alarm.label)
        let alert = AlarmPresentation.Alert(
            title: title,
            stopButton: AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle.fill"),
            secondaryButton: AlarmButton(text: "Challenge", textColor: .white, systemImageName: "brain.head.profile"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<AlarmedAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: AlarmedAlarmMetadata(alarmId: alarm.id, challengeMode: alarm.dismissalMode),
            tintColor: AppColors.primary
        )
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: schedule,
            attributes: attributes,
            stopIntent: OpenChallengeIntent(alarmID: alarm.id),
            secondaryIntent: OpenChallengeIntent(alarmID: alarm.id),
            sound: .default
        )
        _ = try await manager.schedule(id: id, configuration: configuration)
    }

    /// Observes AlarmKit alarm state changes. When one of our alarms starts
    /// alerting while the app is running, surface the in-app ringing screen
    /// with the wake-up challenge.
    static func observeRinging() -> Task<Void, Never> {
        Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                for alarm in alarms where alarm.state == .alerting {
                    NotificationCenter.default.post(
                        name: .alarmTriggered,
                        object: nil,
                        userInfo: ["alarmId": alarm.id.uuidString]
                    )
                }
            }
        }
    }
}
