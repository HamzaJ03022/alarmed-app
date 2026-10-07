import SwiftUI
import Observation

@Observable
final class AlarmsViewModel {
    var alarms: [Alarm] = []
    var history: [AlarmHistory] = []
    var activeAlarmId: String? = nil
    var quotes: [String] = [
        "Rise and shine! Today is full of possibilities.",
        "Every morning is a new beginning, a new chance to change your life.",
        "The only way to do great work is to love what you do.",
        "Your future is created by what you do today, not tomorrow.",
        "Success is not final, failure is not fatal: it is the courage to continue that counts."
    ]
    var volume: Double = 1.0
    var crescendoEnabled: Bool = false
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var hasSeenOnboarding: Bool = false
    var defaultChallengeMode: String = "questions"
    var onboardingPhrase: String = ""
    /// Human-readable outcome of the last scheduling attempt (Settings diagnostics).
    var alarmScheduleStatus: String? = nil
    /// Alarms currently registered with the system scheduler, when exposed.
    var systemAlarmCount: Int? = nil
    /// Output of the last "Run AlarmKit check" tap (Settings diagnostics).
    var alarmCheckResult: String? = nil
    var isRunningCheck: Bool = false

    private let storage = UserDefaults.standard
    private let scheduler: AlarmScheduling = AlarmSchedulerFactory.makeScheduler()

    init() {
        load()
        reconcileOnLaunch()
    }

    /// Repairs alarms that were registered by an older build (or lost after an
    /// update/reboot): the scheduler re-registers any active alarm missing from
    /// the system. Stable alarm IDs make this idempotent.
    private func reconcileOnLaunch() {
        let active = alarms.filter(\.isActive)
        guard !active.isEmpty else { return }
        Task {
            await scheduler.reconcile(alarms: active)
            systemAlarmCount = await scheduler.registeredSystemAlarmCount()
        }
    }

    func addAlarm(_ alarm: Alarm) {
        var newAlarm = alarm
        newAlarm.id = UUID().uuidString
        alarms.append(newAlarm)
        save()
        Task { await scheduleAndRecord(newAlarm) }
    }

    func updateAlarm(id: String, with updates: PartialAlarmUpdate) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        var alarm = alarms[index]
        if let time = updates.time { alarm.time = time }
        if let label = updates.label { alarm.label = label }
        if let isActive = updates.isActive { alarm.isActive = isActive }
        if let repeatDays = updates.repeatDays { alarm.repeatDays = repeatDays }
        if let questionCount = updates.questionCount { alarm.questionCount = questionCount }
        if let difficulty = updates.questionDifficulty { alarm.questionDifficulty = difficulty }
        if let categories = updates.questionCategories { alarm.questionCategories = categories }
        if let vibrate = updates.vibrate { alarm.vibrate = vibrate }
        if let dismissalMode = updates.dismissalMode { alarm.dismissalMode = dismissalMode }
        if let dismissPhrase = updates.dismissPhrase { alarm.dismissPhrase = dismissPhrase }
        alarms[index] = alarm
        save()
        // Cancel first, then reschedule, in one ordered task — an unordered
        // cancel can land after the new schedule and silently delete it.
        Task {
            await scheduler.cancel(id: id)
            if alarm.isActive { await scheduleAndRecord(alarm) }
        }
    }

    func deleteAlarm(id: String) {
        alarms.removeAll { $0.id == id }
        save()
        Task { await scheduler.cancel(id: id) }
    }

    func toggleAlarm(id: String) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isActive.toggle()
        let alarm = alarms[index]
        save()
        if alarm.isActive {
            Task { await scheduleAndRecord(alarm) }
        } else {
            Task { await scheduler.cancel(id: id) }
        }
    }

    func setActiveAlarm(_ id: String?) {
        activeAlarmId = id
    }

    func completeOnboarding(mode: String, phrase: String) {
        hasSeenOnboarding = true
        defaultChallengeMode = mode
        onboardingPhrase = phrase
        save()
    }

    func addHistory(_ item: AlarmHistory) {
        var newItem = item
        newItem.id = UUID().uuidString
        history.append(newItem)
        save()
    }

    func getStreakCount() -> Int {
        let sorted = history
            .filter { !$0.dismissed }
            .sorted { ($0.date > $1.date) }
        let cal = Calendar.current
        var streak = 0
        var currentDate = cal.startOfDay(for: Date())
        for record in sorted {
            guard let recordDate = ISO8601DateFormatter().date(from: record.date) else { continue }
            let recordDay = cal.startOfDay(for: recordDate)
            if recordDay == currentDate {
                streak += 1
                currentDate = cal.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
        }
        return streak
    }

    func clearHistory() { history.removeAll(); save() }

    func clearAlarms() {
        let activeAlarms = alarms.filter(\.isActive)
        alarms.removeAll()
        save()
        // Also unregister the system alarms so nothing keeps ringing.
        Task {
            for alarm in activeAlarms {
                await scheduler.cancel(id: alarm.id)
            }
        }
    }

    func addQuote(_ quote: String) { quotes.append(quote); save() }
    func updateQuote(index: Int, quote: String) {
        guard index < quotes.count else { return }
        quotes[index] = quote; save()
    }
    func deleteQuote(index: Int) {
        guard index < quotes.count else { return }
        quotes.remove(at: index); save()
    }

    // MARK: - Persistence

    private let alarmsKey = "alarmed_alarms"
    private let historyKey = "alarmed_history"
    private let quotesKey = "alarmed_quotes"
    private let volumeKey = "alarmed_volume"
    private let crescendoKey = "alarmed_crescendo"
    private let soundEnabledKey = "alarmed_sound_enabled"
    private let vibrationEnabledKey = "alarmed_vibration_enabled"
    private let hasSeenOnboardingKey = "alarmed_has_seen_onboarding"
    private let defaultChallengeModeKey = "alarmed_default_challenge_mode"
    private let onboardingPhraseKey = "alarmed_onboarding_phrase"

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            storage.set(data, forKey: alarmsKey)
        }
        if let data = try? JSONEncoder().encode(history) {
            storage.set(data, forKey: historyKey)
        }
        storage.set(quotes, forKey: quotesKey)
        storage.set(volume, forKey: volumeKey)
        storage.set(crescendoEnabled, forKey: crescendoKey)
        storage.set(soundEnabled, forKey: soundEnabledKey)
        storage.set(vibrationEnabled, forKey: vibrationEnabledKey)
        storage.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey)
        storage.set(defaultChallengeMode, forKey: defaultChallengeModeKey)
        storage.set(onboardingPhrase, forKey: onboardingPhraseKey)
    }

    private func load() {
        if let data = storage.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
        if let data = storage.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([AlarmHistory].self, from: data) {
            history = decoded
        }
        if let saved = storage.stringArray(forKey: quotesKey) {
            quotes = saved
        }
        volume = storage.double(forKey: volumeKey)
        if storage.object(forKey: volumeKey) == nil { volume = 1.0 }
        crescendoEnabled = storage.bool(forKey: crescendoKey)
        soundEnabled = storage.object(forKey: soundEnabledKey) == nil ? true : storage.bool(forKey: soundEnabledKey)
        vibrationEnabled = storage.object(forKey: vibrationEnabledKey) == nil ? true : storage.bool(forKey: vibrationEnabledKey)
        // Upgrade-safe: users with existing data skip the intro; fresh installs see it
        if storage.object(forKey: hasSeenOnboardingKey) != nil {
            hasSeenOnboarding = storage.bool(forKey: hasSeenOnboardingKey)
        } else if storage.object(forKey: volumeKey) != nil {
            hasSeenOnboarding = true
        }
        if let savedMode = storage.string(forKey: defaultChallengeModeKey) {
            defaultChallengeMode = savedMode
        }
        if storage.object(forKey: onboardingPhraseKey) != nil {
            onboardingPhrase = storage.string(forKey: onboardingPhraseKey) ?? ""
        }
    }

    // MARK: - Native Alarm Scheduling

    /// Schedules with the active scheduler and records the outcome so Settings
    /// can surface scheduling failures instead of failing silently.
    private func scheduleAndRecord(_ alarm: Alarm) async {
        let result = await scheduler.schedule(alarm)
        systemAlarmCount = await scheduler.registeredSystemAlarmCount()
        alarmScheduleStatus = Self.describe(result, time: alarm.time)
    }

    func refreshSystemAlarmCount() {
        Task {
            systemAlarmCount = await scheduler.registeredSystemAlarmCount()
        }
    }

    /// One-tap alarm engine check: registers a throwaway test alarm through
    /// the capability ladder and reports which level the system accepts.
    func runAlarmKitCheck() {
        guard !isRunningCheck else { return }
        isRunningCheck = true
        alarmCheckResult = nil
        Task {
            let result = await scheduler.runDiagnostics()
            systemAlarmCount = await scheduler.registeredSystemAlarmCount()
            alarmCheckResult = result
            isRunningCheck = false
        }
    }

    private static func describe(_ result: AlarmScheduleResult, time: String) -> String {
        if let detail = result.detail {
            if let fallback = result.fallbackError {
                return detail + "\nNotification fallback also failed: \(fallback)."
            }
            return detail
        }
        if let fallback = result.fallbackError {
            let reason = result.alarmKitError ?? "scheduling error"
            return "Could not schedule \(time): \(reason). Notification fallback also failed: \(fallback)."
        }
        if let kitError = result.alarmKitError {
            return "AlarmKit unavailable (\(kitError)) — \(time) is set as a time-sensitive notification."
        }
        if result.usedAlarmKit {
            return "System alarm registered with AlarmKit for \(time)."
        }
        return "Scheduled as a time-sensitive notification for \(time)."
    }
}

struct PartialAlarmUpdate {
    var time: String? = nil
    var label: String? = nil
    var isActive: Bool? = nil
    var repeatDays: [String]? = nil
    var questionCount: Int? = nil
    var questionDifficulty: String? = nil
    var questionCategories: [String]? = nil
    var vibrate: Bool? = nil
    var dismissalMode: String? = nil
    var dismissPhrase: String? = nil
}
