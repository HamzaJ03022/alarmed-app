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

/// How much of the custom challenge UI an alarm registration carries. The
/// system rejected the full combination with a bare error, so registration
/// walks this ladder from richest to simplest and keeps the first accepted
/// level. Nothing degrades silently — every attempt is recorded for the
/// Settings diagnostics card.
enum AlarmCapabilityLevel: Int, CaseIterable {
    /// Done + Challenge buttons, both wired to the challenge intent.
    case fullChallenge = 1
    /// Challenge button + intent; Done uses system stop behavior.
    case challengeOnly = 2
    /// System-standard alert presentation, no custom buttons or intents.
    case standardButtons = 3

    var label: String {
        switch self {
        case .fullChallenge: return "full challenge layer (Done + Challenge buttons)"
        case .challengeOnly: return "challenge-only layer (Challenge button, system Done)"
        case .standardButtons: return "standard system buttons"
        }
    }
}

/// One rung of the capability ladder.
struct AlarmKitAttempt {
    var level: AlarmCapabilityLevel
    var succeeded: Bool
    var errorDetail: String?
}

/// Outcome of one registration pass, rendered into the Settings card.
struct AlarmKitDiagnostics {
    var permissionLine: String
    var attempts: [AlarmKitAttempt]
    var acceptedLevel: AlarmCapabilityLevel?

    func summary() -> String {
        var lines = [permissionLine]
        if let accepted = acceptedLevel {
            lines.append("Registered with AlarmKit — \(accepted.label).")
        } else {
            lines.append("AlarmKit rejected every alarm setup.")
        }
        for attempt in attempts where !attempt.succeeded {
            lines.append("Rejected: \(attempt.level.label) — \(attempt.errorDetail ?? "unknown error")")
        }
        return lines.joined(separator: "\n")
    }
}

/// Schedules alarms with AlarmKit on iOS 26+. Registration follows Apple's
/// official sample shape (relative schedules for one-time and weekly alarms)
/// and falls back to time-sensitive notifications per alarm only when the
/// system rejects every capability level.
@available(iOS 26.0, *)
struct AlarmKitScheduler: AlarmScheduling {
    /// Disambiguates from the app's own `Alarm` model struct.
    private typealias SystemAlarm = AlarmKit.Alarm

    private static let logger = Logger(subsystem: "com.nyytech.alarmed", category: "AlarmKit")

    /// Single-flight permission requests: reconcile-on-launch, alarm edits and
    /// the manual check all run on the main actor, so a plain static Task slot
    /// safely shares one in-flight request between them.
    private static var inFlightAuthorization: Task<AlarmManager.AuthorizationState, Error>?

    func schedule(_ alarm: Alarm) async -> AlarmScheduleResult {
        guard alarm.isActive else {
            return AlarmScheduleResult(alarmKitError: nil, fallbackError: nil, usedAlarmKit: false)
        }
        let kitId = UUID(uuidString: alarm.id) ?? UUID()
        let diagnostics = await Self.registerWithAlarmKit(alarm, id: kitId)
        if let accepted = diagnostics.acceptedLevel {
            Self.logger.info("AlarmKit alarm registered (id: \(alarm.id, privacy: .public)) at level \(accepted.rawValue, privacy: .public)")
            return AlarmScheduleResult(
                alarmKitError: nil,
                fallbackError: nil,
                usedAlarmKit: true,
                detail: diagnostics.summary()
            )
        }
        Self.logger.error("AlarmKit rejected all levels (id: \(alarm.id, privacy: .public))")
        let fallbackError = await NotificationManager.shared.scheduleAlarm(alarm)
        var detail = diagnostics.summary()
        detail += "\nUsing a time-sensitive notification instead."
        if let fallback = fallbackError {
            detail += "\nNotification fallback also failed: \(fallback)"
        }
        return AlarmScheduleResult(
            alarmKitError: diagnostics.attempts.last?.errorDetail ?? "unknown AlarmKit error",
            fallbackError: fallbackError,
            usedAlarmKit: false,
            detail: detail
        )
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

    /// Repairs alarms lost between sessions: any active alarm whose stable ID
    /// is not registered with AlarmKit gets scheduled again. Stable IDs make
    /// this idempotent — no cancel/churn for alarms that are already live.
    func reconcile(alarms: [Alarm]) async {
        guard let scheduled = try? AlarmManager.shared.alarms else { return }
        let scheduledIds = Set(scheduled.map(\.id.uuidString))
        for alarm in alarms where alarm.isActive && !scheduledIds.contains(alarm.id) {
            _ = await schedule(alarm)
        }
    }

    /// One-tap check from Settings: registers a throwaway alarm about two
    /// minutes out through the same capability ladder, reports which level the
    /// system accepted, then removes the alarm.
    func runDiagnostics() async -> String {
        let probeId = UUID()
        let fireDate = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
        let timeString: String
        if let hour = components.hour, let minute = components.minute {
            timeString = String(format: "%02d:%02d", hour, minute)
        } else {
            timeString = "23:59"
        }
        let probe = Alarm(id: probeId.uuidString, time: timeString, label: "Alarmed check")
        let diagnostics = await Self.registerWithAlarmKit(probe, id: probeId)
        try? await AlarmManager.shared.cancel(id: probeId)
        NotificationManager.shared.cancelAlarm(id: probeId.uuidString)
        return diagnostics.summary()
    }

    // MARK: - Registration

    private static func registerWithAlarmKit(_ alarm: Alarm, id: UUID) async -> AlarmKitDiagnostics {
        let manager = AlarmManager.shared

        // Ground truth first: the raw state string ends up in the Settings
        // card, so a state this SDK does not recognize is visible instead of
        // silently blocking registration.
        let rawState = String(describing: manager.authorizationState)

        // Only a documented .denied stops registration. Every other state —
        // including ones this SDK version does not know — goes straight to the
        // system: schedule() can still trigger the permission prompt itself,
        // and whatever the system answers becomes the visible diagnostic.
        if manager.authorizationState == .denied {
            return AlarmKitDiagnostics(
                permissionLine: "Permission: denied — turn on Alarms for Alarmed in the Settings app, then recreate the alarm.",
                attempts: [],
                acceptedLevel: nil
            )
        }

        var permissionLine = "Permission: system reports \(rawState)."
        if manager.authorizationState == .notDetermined {
            do {
                let state = try await requestAuthorizationSingleFlight()
                if manager.authorizationState == .denied {
                    return AlarmKitDiagnostics(
                        permissionLine: "Permission: the prompt was declined — turn on Alarms for Alarmed in the Settings app, then recreate the alarm.",
                        attempts: [],
                        acceptedLevel: nil
                    )
                }
                permissionLine = state == .authorized
                    ? "Permission: authorized."
                    : "Permission: system returned \(String(describing: state)) after the prompt."
            } catch {
                // A failed prompt request no longer blocks registration — the
                // system may still accept a direct schedule() call.
                permissionLine = "Permission: request failed (\(describe(error))) — attempting registration anyway."
            }
        }

        guard let schedule = makeSchedule(for: alarm) else {
            return AlarmKitDiagnostics(
                permissionLine: permissionLine,
                attempts: [AlarmKitAttempt(
                    level: .fullChallenge,
                    succeeded: false,
                    errorDetail: "the alarm time \"\(alarm.time)\" could not be parsed"
                )],
                acceptedLevel: nil
            )
        }

        let title = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Wake up!" : alarm.label)
        var attempts: [AlarmKitAttempt] = []
        for level in AlarmCapabilityLevel.allCases {
            let configuration = makeConfiguration(
                for: level,
                alarm: alarm,
                schedule: schedule,
                title: title
            )
            do {
                _ = try await manager.schedule(id: id, configuration: configuration)
                attempts.append(AlarmKitAttempt(level: level, succeeded: true, errorDetail: nil))
                return AlarmKitDiagnostics(
                    permissionLine: permissionLine,
                    attempts: attempts,
                    acceptedLevel: level
                )
            } catch {
                Self.logger.error("AlarmKit rejected level \(level.rawValue, privacy: .public) (id: \(alarm.id, privacy: .public)): \(error.localizedDescription, privacy: .public)")
                attempts.append(AlarmKitAttempt(level: level, succeeded: false, errorDetail: describe(error)))
            }
        }
        return AlarmKitDiagnostics(
            permissionLine: permissionLine,
            attempts: attempts,
            acceptedLevel: nil
        )
    }

    /// Apple's sample schedules every alarm as a relative time — one-time with
    /// `.never`, repeating with the selected weekdays. No date-based schedules.
    private static func makeSchedule(for alarm: Alarm) -> SystemAlarm.Schedule? {
        let parts = alarm.time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute) else {
            return nil
        }
        let weekdayMap: [String: Locale.Weekday] = [
            "sun": .sunday, "mon": .monday, "tue": .tuesday, "wed": .wednesday,
            "thu": .thursday, "fri": .friday, "sat": .saturday
        ]
        let weekdays = alarm.repeatDays.compactMap { weekdayMap[$0] }
        let recurrence: SystemAlarm.Schedule.Relative.Recurrence = weekdays.isEmpty ? .never : .weekly(weekdays)
        return SystemAlarm.Schedule.relative(.init(
            time: .init(hour: hour, minute: minute),
            repeats: recurrence
        ))
    }

    private static func makeConfiguration(
        for level: AlarmCapabilityLevel,
        alarm: Alarm,
        schedule: SystemAlarm.Schedule,
        title: LocalizedStringResource
    ) -> AlarmManager.AlarmConfiguration<AlarmedAlarmMetadata> {
        let challengeButton = AlarmButton(
            text: "Challenge",
            textColor: .white,
            systemImageName: "brain.head.profile"
        )
        // The four-parameter alert initializer (with stopButton) is the
        // iOS 26.0 API; variants omitting stopButton require iOS 26.1.
        let alert = AlarmPresentation.Alert(
            title: title,
            stopButton: AlarmButton(
                text: "Done",
                textColor: .white,
                systemImageName: "stop.circle.fill"
            ),
            secondaryButton: level == .standardButtons ? nil : challengeButton,
            secondaryButtonBehavior: level == .standardButtons ? nil : .custom
        )

        let attributes = AlarmAttributes<AlarmedAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: AlarmedAlarmMetadata(alarmId: alarm.id, challengeMode: alarm.dismissalMode),
            tintColor: AppColors.primary
        )

        switch level {
        case .fullChallenge:
            let intent = OpenChallengeIntent(alarmID: alarm.id)
            return AlarmManager.AlarmConfiguration(
                countdownDuration: nil,
                schedule: schedule,
                attributes: attributes,
                stopIntent: intent,
                secondaryIntent: intent,
                sound: .default
            )
        case .challengeOnly:
            return AlarmManager.AlarmConfiguration(
                countdownDuration: nil,
                schedule: schedule,
                attributes: attributes,
                secondaryIntent: OpenChallengeIntent(alarmID: alarm.id),
                sound: .default
            )
        case .standardButtons:
            return AlarmManager.AlarmConfiguration(
                countdownDuration: nil,
                schedule: schedule,
                attributes: attributes,
                sound: .default
            )
        }
    }

    /// Shares one in-flight permission request across reconcile-on-launch,
    /// alarm edits and the manual check instead of letting them race.
    private static func requestAuthorizationSingleFlight() async throws -> AlarmManager.AuthorizationState {
        if let inFlight = inFlightAuthorization {
            return try await inFlight.value
        }
        let task = Task { try await AlarmManager.shared.requestAuthorization() }
        inFlightAuthorization = task
        defer { inFlightAuthorization = nil }
        return try await task.value
    }

    /// Ground-truth lines for the Settings card so every screenshot pins down
    /// the exact binary: build number, embedded permission text, bundled tone,
    /// and the raw permission state.
    func groundTruthLines() -> [String] {
        var lines = AlarmBundleFacts.lines
        if let raw = rawPermissionStateLine() {
            lines.append(raw)
        }
        return lines
    }

    /// The permission state exactly as the system reports it — including
    /// states this SDK version does not know.
    func rawPermissionStateLine() -> String? {
        "System permission state: \(String(describing: AlarmManager.shared.authorizationState))"
    }

    /// Full NSError context — the bare localizedDescription ("error 1") is
    /// useless for remote debugging.
    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        var detail = "code \(nsError.code), domain \(nsError.domain)"
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            detail += " (underlying: code \(underlying.code), domain \(underlying.domain))"
        }
        return "\(detail) — \(error.localizedDescription)"
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
