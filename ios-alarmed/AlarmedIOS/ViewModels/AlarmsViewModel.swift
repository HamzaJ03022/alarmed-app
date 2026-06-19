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

    private let storage = UserDefaults.standard

    init() { load() }

    func addAlarm(_ alarm: Alarm) {
        var newAlarm = alarm
        newAlarm.id = UUID().uuidString
        alarms.append(newAlarm)
        save()
        scheduleAlarmNotification(newAlarm)
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
        alarms[index] = alarm
        save()
        cancelAlarmNotification(id)
        if alarm.isActive { scheduleAlarmNotification(alarm) }
    }

    func deleteAlarm(id: String) {
        alarms.removeAll { $0.id == id }
        cancelAlarmNotification(id)
        save()
    }

    func toggleAlarm(id: String) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isActive.toggle()
        if alarms[index].isActive {
            scheduleAlarmNotification(alarms[index])
        } else {
            cancelAlarmNotification(id)
        }
        save()
    }

    func setActiveAlarm(_ id: String?) {
        activeAlarmId = id
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
    func clearAlarms() { alarms.removeAll(); save() }

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
    }

    // MARK: - Native Alarm Scheduling

    private func scheduleAlarmNotification(_ alarm: Alarm) {
        let manager = NotificationManager.shared
        manager.scheduleAlarm(alarm)
    }

    private func cancelAlarmNotification(_ id: String) {
        NotificationManager.shared.cancelAlarm(id: id)
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
}
