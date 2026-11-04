import ActivityKit
import AlarmKit
import Foundation
import os
import SwiftUI
import UserNotifications

/// Deterministic IDs for the wake-up check-in's follow-up rings. Each
/// follow-up alarm ID is the alarm's UUID with byte 14 XOR-ed by the ring
/// index (the re-ring backups use byte 15, so the two never collide), letting
/// a ringing follow-up be traced back to its alarm without any lookup table.
/// The IDs are also persisted with the check-in state so every one can be
/// cancelled individually even after a relaunch.
enum AlarmCheckInIds {
    /// Follow-up system alarm rings after an unanswered check-in.
    static let followUpCount = 3

    static func followUpAlarmIds(for alarmId: String) -> [UUID] {
        guard let base = UUID(uuidString: alarmId) else { return [] }
        return (1...followUpCount).map { index in
            var bytes = base.uuid
            bytes.14 ^= UInt8(index)
            return UUID(uuid: bytes)
        }
    }

    /// Resolves a system alarm ID to the alarm whose check-in follow-up rang,
    /// or nil when the ID is not one of them.
    static func parentAlarmId(for systemId: String, among alarmIds: [String]) -> String? {
        guard let uuid = UUID(uuidString: systemId) else { return nil }
        for alarmId in alarmIds where followUpAlarmIds(for: alarmId).contains(uuid) {
            return alarmId
        }
        return nil
    }

    static func checkInNotificationId(for alarmId: String) -> String { "checkin-\(alarmId)" }

    static func followUpNotificationId(for alarmId: String, index: Int) -> String {
        "checkin-\(alarmId)-fu\(index)"
    }
}

/// Notification identifiers shared by the scheduler and the delegate that
/// handles the lock-screen "I'm awake" action.
enum CheckInNotification {
    static let categoryId = "CHECKIN_CATEGORY"
    /// No `.foreground` and no `.authenticationRequired` on purpose: the
    /// action runs in the background straight from the lock screen, without
    /// unlocking the phone.
    static let awakeActionId = "IM_AWAKE"
    static let userInfoAlarmKey = "checkInAlarmId"
}

/// What a booking attempt produced, worded honestly for the wake-up screen.
struct CheckInOutcome: Equatable {
    enum Kind: String {
        case booked
        case alarmOnly
        case notificationOnly
        case partial
        case notPossible
    }

    let kind: Kind
    let message: String
    let fireDate: Date?
}

/// One persisted check-in: everything needed to cancel each individual
/// follow-up ring and to spot stale ones.
struct CheckInState: Codable {
    enum Status: String, Codable {
        case pending
        case confirmed
    }

    var alarmId: String
    var alarmLabel: String
    var alarmTime: String
    /// When the "Are you awake?" nudge fires.
    var fireDate: Date
    /// The latest follow-up ring — check-ins expire some minutes after it.
    var lastRingDate: Date
    var status: Status = .pending
    /// AlarmKit follow-up ring IDs that were accepted at booking time.
    var followUpAlarmIds: [String] = []
    /// Notification IDs booked for this check-in (the nudge + follow-ups).
    var notificationIds: [String] = []
    /// Honest booking note ("2 of 3 follow-up alarms registered").
    var bookingNote: String? = nil
    /// Fillled when a confirmed check-in could not fully cancel its rings.
    var cancelFailures: [String] = []
}

/// Schedules and cancels the wake-up check-in: a friendly "Are you awake?"
/// nudge after the challenge is solved, backed by real AlarmKit follow-up
/// alarms when possible and plain notifications otherwise. Nothing is ever
/// reported as booked unless the system confirmed every registration.
@MainActor
final class WakeUpCheckInStore {
    static let shared = WakeUpCheckInStore()

    private static let logger = Logger(subsystem: "com.nyytech.alarmed", category: "CheckIn")
    private static let storageKey = "alarmed_checkin_states"
    /// Check-ins are cleaned up this long after their last possible ring.
    private static let expiryGrace: TimeInterval = 20 * 60

    private var states: [String: CheckInState] = [:]
    /// Rolling diagnostics log (cancel attempts, booking results).
    private(set) var log: [String] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([String: CheckInState].self, from: data) {
            states = decoded
        }
    }

    // MARK: - Booking

    /// Books the check-in for an alarm whose challenge was just solved.
    /// `fireDate` is `delayMinutes` after the solve, so this must be called
    /// right after a successful challenge, never speculatively.
    func scheduleCheckIn(for alarm: Alarm) async -> CheckInOutcome {
        // Solving again replaces any earlier check-in instead of doubling up.
        await cancelStateAndRings(for: alarm.id)
        let delay = TimeInterval(alarm.checkInDelayMinutes) * 60
        let fireDate = Date().addingTimeInterval(delay)

        let alarmPermission = alarmKitAvailability()
        let notificationStatus = await notificationAuthorization()

        // Both engines off: no honest way to follow up.
        if !alarmPermission.canSchedule && notificationStatus == .denied {
            let outcome = CheckInOutcome(
                kind: .notPossible,
                message: "Check-in needs notifications or alarms turned on — enable one for Alarmed in the Settings app and it will be armed next time.",
                fireDate: nil
            )
            recordLog("Booking refused for \(alarm.id): no alarms and no notification permission.")
            return outcome
        }

        if alarmPermission.canSchedule {
            let outcome = await bookWithSystemAlarms(alarm: alarm, fireDate: fireDate, notificationsAllowed: notificationStatus != .denied)
            return outcome
        }
        return await bookWithNotifications(alarm: alarm, fireDate: fireDate)
    }

    /// iOS 26+ with Alarms allowed: a nudge notification (unless notifications
    /// are off, in which case the first system alarm IS the check-in) followed
    /// by up to 3 real follow-up alarms a minute apart.
    private func bookWithSystemAlarms(alarm: Alarm, fireDate: Date, notificationsAllowed: Bool) async -> CheckInOutcome {
        guard #available(iOS 26.0, *) else {
            return await bookWithNotifications(alarm: alarm, fireDate: fireDate)
        }

        var notificationIds: [String] = []
        var firstRingDelay = 2 * 60 // the nudge gets 2 minutes to be answered
        if notificationsAllowed {
            if let nudgeError = await scheduleCheckInNotification(alarm: alarm, fireDate: fireDate) {
                recordLog("Check-in nudge failed for \(alarm.id): \(nudgeError)")
            } else {
                notificationIds.append(AlarmCheckInIds.checkInNotificationId(for: alarm.id))
            }
        } else {
            // No notification to respond to, so the first ring is the
            // check-in itself — no extra 2-minute window.
            firstRingDelay = 0
        }

        let followUpIds = AlarmCheckInIds.followUpAlarmIds(for: alarm.id)
        var registered: [String] = []
        var lastError: String?
        for (index, id) in followUpIds.enumerated() {
            let ringDate = fireDate.addingTimeInterval(TimeInterval((firstRingDelay + index * 60)))
            do {
                try await Self.scheduleFollowUpAlarm(id: id, fireDate: ringDate, alarm: alarm)
                registered.append(id.uuidString)
            } catch {
                lastError = Self.describe(error)
                Self.logger.error("Follow-up \(index + 1) rejected (alarm \(alarm.id, privacy: .public)): \(lastError ?? "?", privacy: .public)")
            }
        }

        // Verify against the system, then retry any that silently failed once.
        var missing = await missingFollowUpIds(registered: registered, expected: followUpIds)
        if !missing.isEmpty {
            recordLog("Retrying \(missing.count) follow-up ring(s) not confirmed by the system for \(alarm.id).")
            for id in missing {
                let index = followUpIds.firstIndex(of: id).map { $0 + 1 } ?? 1
                let ringDate = fireDate.addingTimeInterval(TimeInterval(firstRingDelay + (index - 1) * 60))
                do {
                    try await Self.scheduleFollowUpAlarm(id: id, fireDate: ringDate, alarm: alarm)
                    registered.append(id.uuidString)
                } catch {
                    lastError = Self.describe(error)
                }
            }
            missing = await missingFollowUpIds(registered: registered, expected: followUpIds)
        }

        if registered.isEmpty {
            // Total AlarmKit failure: honest notification fallback instead.
            recordLog("All follow-up alarms rejected for \(alarm.id) (\(lastError ?? "unknown")) — falling back to notifications.")
            return await bookWithNotifications(alarm: alarm, fireDate: fireDate)
        }

        let armed = registered.count
        let total = AlarmCheckInIds.followUpCount
        let lastRingDate = fireDate.addingTimeInterval(TimeInterval(firstRingDelay + (total - 1) * 60))
        let time = Self.clockString(from: fireDate)
        let outcome: CheckInOutcome
        var bookingNote: String?
        if missing.isEmpty {
            outcome = CheckInOutcome(
                kind: notificationsAllowed ? .booked : .alarmOnly,
                message: notificationsAllowed
                    ? "We'll check in at \(time) — if you don't answer, a real alarm rings."
                    : "We'll check in at \(time) with a real alarm — it is the check-in itself, since notifications are off.",
                fireDate: fireDate
            )
        } else {
            bookingNote = "Check-in partly set: \(armed) of \(total) follow-up alarms registered."
            outcome = CheckInOutcome(
                kind: .partial,
                message: "\(bookingNote!) We'll still check in at \(time).",
                fireDate: fireDate
            )
        }
        let state = CheckInState(
            alarmId: alarm.id,
            alarmLabel: alarm.label,
            alarmTime: alarm.time,
            fireDate: fireDate,
            lastRingDate: lastRingDate,
            followUpAlarmIds: registered,
            notificationIds: notificationIds,
            bookingNote: bookingNote
        )
        states[alarm.id] = state
        persist()
        recordLog("Booked \(armed)/\(total) follow-up alarms for \(alarm.id); nudge \(notificationIds.isEmpty ? "not" : "") scheduled.")
        return outcome
    }

    /// Older iOS or Alarms permission off: notifications only — never
    /// described as alarms.
    private func bookWithNotifications(alarm: Alarm, fireDate: Date) async -> CheckInOutcome {
        var ids: [String] = []
        if let nudgeError = await scheduleCheckInNotification(alarm: alarm, fireDate: fireDate) {
            recordLog("Check-in nudge failed for \(alarm.id): \(nudgeError)")
        } else {
            ids.append(AlarmCheckInIds.checkInNotificationId(for: alarm.id))
        }

        var failures: [String] = []
        for index in 1...AlarmCheckInIds.followUpCount {
            let ringDate = fireDate.addingTimeInterval(TimeInterval((1 + index) * 60)) // +2, +3, +4 minutes
            let id = AlarmCheckInIds.followUpNotificationId(for: alarm.id, index: index)
            if let error = await scheduleFollowUpNotification(alarm: alarm, fireDate: ringDate, id: id) {
                failures.append(error)
            } else {
                ids.append(id)
            }
        }

        // Verify the system actually holds every request.
        let pendingIds = Set(await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier))
        let missing = ids.filter { !pendingIds.contains($0) }

        if ids.isEmpty {
            let outcome = CheckInOutcome(
                kind: .notPossible,
                message: "The check-in couldn't be scheduled (\(failures.first ?? "notifications unavailable")).",
                fireDate: nil
            )
            recordLog("Notification-only booking failed entirely for \(alarm.id).")
            return outcome
        }

        let time = Self.clockString(from: fireDate)
        let note: String?
        let outcome: CheckInOutcome
        if missing.isEmpty {
            outcome = CheckInOutcome(
                kind: .notificationOnly,
                message: "We'll check in at \(time) — as notifications, not alarms. They play a short sound once, stay silent if your phone is on Silent, and may be held back by Focus.",
                fireDate: fireDate
            )
            note = nil
        } else {
            note = "Check-in partly set: \(ids.count - missing.count) of \(ids.count) reminders registered."
            outcome = CheckInOutcome(kind: .partial, message: "\(note!) We'll still check in at \(time).", fireDate: fireDate)
        }
        let state = CheckInState(
            alarmId: alarm.id,
            alarmLabel: alarm.label,
            alarmTime: alarm.time,
            fireDate: fireDate,
            lastRingDate: fireDate.addingTimeInterval(TimeInterval((1 + AlarmCheckInIds.followUpCount) * 60)),
            followUpAlarmIds: [],
            notificationIds: ids,
            bookingNote: note
        )
        states[alarm.id] = state
        persist()
        recordLog("Booked notification-only check-in for \(alarm.id) (\(ids.count) requests).")
        return outcome
    }

    // MARK: - Confirmation

    /// Explicit "I'm awake". Delivery alone never calls this. Cancels every
    /// booked ring for this check-in, retrying until the system confirms they
    /// are gone — a known, imminent alarm is never left relying on the next
    /// app launch. Returns once cancellation is exhausted.
    func confirm(alarmId: String) async {
        guard var state = states[alarmId] else {
            recordLog("Ignored a stale I'm-awake tap for \(alarmId) (no pending check-in).")
            return
        }
        guard state.status == .pending else { return } // double-tap safe
        state.status = .confirmed
        states[alarmId] = state
        persist()
        Self.logger.info("Check-in confirmed (alarm \(alarmId, privacy: .public))")
        recordLog("Confirmed check-in for \(alarmId); cancelling rings.")

        let failures = await exhaustivelyCancel(state)
        if failures.isEmpty {
            states.removeValue(forKey: alarmId)
            persist()
        } else {
            state.cancelFailures = failures
            states[alarmId] = state
            persist()
            recordLog("CANCEL FAILED for \(alarmId): \(failures.joined(separator: "; "))")
            Self.logger.error("Cancellation failures for \(alarmId, privacy: .public): \(failures.joined(separator: "; "), privacy: .public)")
        }
    }

    /// Cancels every ID one by one, then verifies against the system and
    /// retries whatever remains, repeatedly, before giving up.
    private func exhaustivelyCancel(_ state: CheckInState) async -> [String] {
        var remaining: [String] = []
        for attempt in 1...4 {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: state.notificationIds)

            if #available(iOS 26.0, *) {
                let alarmIds = state.followUpAlarmIds.compactMap(UUID.init(uuidString:))
                if let current = try? AlarmManager.shared.alarms {
                    for systemAlarm in current where alarmIds.contains(systemAlarm.id) && systemAlarm.state == .alerting {
                        try? await AlarmManager.shared.stop(id: systemAlarm.id)
                    }
                }
                for id in alarmIds {
                    try? await AlarmManager.shared.cancel(id: id)
                }
            }

            remaining = await verifyStillArmed(state)
            if remaining.isEmpty { break }
            recordLog("Cancel attempt \(attempt) left \(remaining.count) ring(s) — retrying.")
            try? await Task.sleep(for: .milliseconds(400))
        }
        return remaining
    }

    /// Asks iOS what is actually still scheduled, so a cancelled-in-code ring
    /// that the system kept is caught instead of trusted away.
    private func verifyStillArmed(_ state: CheckInState) async -> [String] {
        var remaining: [String] = []
        if #available(iOS 26.0, *) {
            let alarmIds = Set(state.followUpAlarmIds)
            if let current = try? AlarmManager.shared.alarms {
                for systemAlarm in current where alarmIds.contains(systemAlarm.id.uuidString) {
                    remaining.append("system alarm \(systemAlarm.id.uuidString)")
                }
            }
        }
        let pendingIds = Set(await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier))
        for id in state.notificationIds where pendingIds.contains(id) {
            remaining.append("notification \(id)")
        }
        return remaining
    }

    // MARK: - Cancelling without confirming

    /// User-initiated cancellation: alarm deleted, switched off, check-in
    /// turned off, or the alarm ringing again. Not a confirmation.
    func cancel(for alarmId: String) async {
        guard let state = states[alarmId] else { return }
        await cancelStateAndRings(for: alarmId, state: state)
    }

    /// Stops an alerting follow-up ring whose check-in no longer exists, so a
    /// stale system alarm never rings on after a confirmation.
    func silenceLeftoverRing(alarmId: String) async {
        guard #available(iOS 26.0, *) else { return }
        let alarmIds = AlarmCheckInIds.followUpAlarmIds(for: alarmId)
        guard let current = try? AlarmManager.shared.alarms else { return }
        for systemAlarm in current where alarmIds.contains(systemAlarm.id) && systemAlarm.state == .alerting {
            try? await AlarmManager.shared.stop(id: systemAlarm.id)
        }
    }

    private func cancelStateAndRings(for alarmId: String, state: CheckInState? = nil) async {
        let target = state ?? states[alarmId]
        guard let target else { return }
        let center = UNUserNotificationCenter.current()
        if !target.notificationIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: target.notificationIds)
        }
        if #available(iOS 26.0, *) {
            for id in target.followUpAlarmIds.compactMap(UUID.init(uuidString:)) {
                try? await AlarmManager.shared.cancel(id: id)
            }
        }
        states.removeValue(forKey: alarmId)
        persist()
        recordLog("Cancelled check-in for \(alarmId).")
    }

    // MARK: - Lifecycle & diagnostics

    func pendingState(for alarmId: String) -> CheckInState? {
        states[alarmId].flatMap { $0.status == .pending ? $0 : nil }
    }

    /// Drops check-ins whose last possible ring is long past. Run at launch.
    func cleanUpExpired() async {
        let cutoff = Date().addingTimeInterval(-Self.expiryGrace)
        for (_, state) in states where state.lastRingDate < cutoff {
            await cancelStateAndRings(for: state.alarmId, state: state)
            recordLog("Expired stale check-in for \(state.alarmId).")
        }
    }

    /// Ground truth for the diagnostics card: what is pending, what the
    /// system still holds, and any confirmation-cancel failures.
    func diagnosticLines() async -> [String] {
        if states.isEmpty { return ["No wake-up check-ins pending."] }
        var lines: [String] = []
        for state in states.values.sorted(by: { $0.fireDate < $1.fireDate }) {
            let name = state.alarmLabel.isEmpty ? "Alarm at \(state.alarmTime)" : state.alarmLabel
            switch state.status {
            case .pending:
                lines.append("\(name): check-in due \(Self.clockString(from: state.fireDate)) (\(state.followUpAlarmIds.count) of \(AlarmCheckInIds.followUpCount) follow-up alarms armed)")
            case .confirmed:
                let risk = state.cancelFailures.isEmpty ? "" : " — at risk: \(state.cancelFailures.joined(separator: "; "))"
                lines.append("\(name): confirmed\(risk)")
            }
        }
        lines.append(contentsOf: log.suffix(5))
        return lines
    }

    private func recordLog(_ line: String) {
        let stamp = Self.clockString(from: Date())
        log.append("[\(stamp)] \(line)")
        if log.count > 20 { log.removeFirst(log.count - 20) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - Permissions

    struct AlarmKitAvailability {
        let canSchedule: Bool
        let detail: String
    }

    private func alarmKitAvailability() -> AlarmKitAvailability {
        guard #available(iOS 26.0, *) else {
            return AlarmKitAvailability(
                canSchedule: false,
                detail: "This iPhone cannot set system alarms (needs iOS 26)."
            )
        }
        let state = AlarmManager.shared.authorizationState
        if state == .denied {
            return AlarmKitAvailability(canSchedule: false, detail: "Alarms permission is denied.")
        }
        return AlarmKitAvailability(canSchedule: true, detail: "Alarms permission: \(String(describing: state)).")
    }

    private func notificationAuthorization() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])) ?? false
            return granted ? .authorized : .denied
        }
        return settings.authorizationStatus
    }

    // MARK: - Scheduling primitives

    /// The friendly "Are you awake?" nudge. Returns an error string or nil.
    private func scheduleCheckInNotification(alarm: Alarm, fireDate: Date) async -> String? {
        let content = Self.checkInContent(alarm: alarm, title: "Are you awake?", body: "Just checking you're up and ready to start your day.")
        return await addNotification(
            content: content,
            id: AlarmCheckInIds.checkInNotificationId(for: alarm.id),
            fireDate: fireDate
        )
    }

    private func scheduleFollowUpNotification(alarm: Alarm, fireDate: Date, id: String) async -> String? {
        let content = Self.checkInContent(alarm: alarm, title: "Still with us?", body: "Open Alarmed and tap I'm awake to check in.")
        return await addNotification(content: content, id: id, fireDate: fireDate)
    }

    private nonisolated static func checkInContent(alarm: Alarm, title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = [CheckInNotification.userInfoAlarmKey: alarm.id]
        content.categoryIdentifier = CheckInNotification.categoryId
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = alarm.id
        let tone = AlarmSound.sound(forID: alarm.sound)
        if tone.isBundled {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(tone.fileName))
        }
        return content
    }

    private func addNotification(content: UNMutableNotificationContent, id: String, fireDate: Date) async -> String? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return nil
        } catch {
            return Self.describe(error)
        }
    }

    /// One follow-up system alarm: a full-screen alarm that breaks through
    /// Silent mode and Focus, whose only button is "I'm awake" — wired to an
    /// intent that confirms the check-in and cancels the remaining rings.
    /// Silencing with the side button stops this ring only.
    @available(iOS 26.0, *)
    private static func scheduleFollowUpAlarm(id: UUID, fireDate: Date, alarm: Alarm) async throws {
        typealias SystemAlarm = AlarmKit.Alarm
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Still with us?" : "Still with us? — \(alarm.label)"),
            stopButton: AlarmButton(
                text: "I'm awake",
                textColor: .white,
                systemImageName: "sun.max.fill"
            ),
            secondaryButton: nil,
            secondaryButtonBehavior: nil
        )
        let tone = AlarmSound.sound(forID: alarm.sound)
        let sound = AlertConfiguration.AlertSound.named(tone.isBundled ? tone.fileName : AlarmKitScheduler.toneFileName)
        let attributes = AlarmAttributes<AlarmedAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: AlarmedAlarmMetadata(alarmId: alarm.id, challengeMode: alarm.dismissalMode),
            tintColor: AppColors.primary
        )
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: SystemAlarm.Schedule.fixed(fireDate),
            attributes: attributes,
            stopIntent: ConfirmAwakeIntent(alarmID: alarm.id),
            sound: sound
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    /// Follow-up IDs that the system does not actually hold.
    @available(iOS 26.0, *)
    private func missingFollowUpIds(registered: [String], expected: [UUID]) async -> [UUID] {
        let registeredSet = Set(registered)
        guard let current = try? AlarmManager.shared.alarms else {
            return [] // cannot enumerate: trust the schedule results
        }
        let systemIds = Set(current.map(\.id))
        return expected.filter { id in
            registeredSet.contains(id.uuidString) && !systemIds.contains(id)
        }
    }

    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "code \(nsError.code), domain \(nsError.domain) — \(error.localizedDescription)"
    }

    static func clockString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
