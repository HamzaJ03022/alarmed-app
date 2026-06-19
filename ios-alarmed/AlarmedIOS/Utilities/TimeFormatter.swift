import Foundation

enum TimeFormatter {
    static func formatTime12h(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else { return time }
        let period = hours >= 12 ? "PM" : "AM"
        let hour12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return "\(hour12):\(String(format: "%02d", minutes)) \(period)"
    }

    static func formatTimeFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func formatRepeatDays(_ repeatDays: [String]) -> String {
        if repeatDays.isEmpty { return "Once" }
        if repeatDays.count == 7 { return "Every day" }
        let weekdays: Set<String> = ["mon", "tue", "wed", "thu", "fri"]
        let weekends: Set<String> = ["sat", "sun"]
        let set = Set(repeatDays)
        if set == weekdays { return "Weekdays" }
        if set == weekends { return "Weekends" }
        return repeatDays.map { $0.prefix(2).capitalized }.joined(separator: ", ")
    }

    static func shouldRingToday(_ repeatDays: [String]) -> Bool {
        if repeatDays.isEmpty { return true }
        let dayNames = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        return repeatDays.contains(dayNames[todayIndex])
    }

    static func getNextAlarmTime(time: String, repeatDays: [String]) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else { return nil }
        let now = Date()
        let cal = Calendar.current
        var alarmDate = cal.date(bySettingHour: hours, minute: minutes, second: 0, of: now) ?? now

        if repeatDays.isEmpty {
            if alarmDate <= now {
                alarmDate = cal.date(byAdding: .day, value: 1, to: alarmDate) ?? alarmDate
            }
            return alarmDate
        }

        let dayNames = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
        let todayIndex = cal.component(.weekday, from: now) - 1
        if alarmDate > now && repeatDays.contains(dayNames[todayIndex]) {
            return alarmDate
        }

        for offset in 1...7 {
            let nextDate = cal.date(byAdding: .day, value: offset, to: alarmDate) ?? alarmDate
            let dayIndex = cal.component(.weekday, from: nextDate) - 1
            if repeatDays.contains(dayNames[dayIndex]) {
                return nextDate
            }
        }
        return nil
    }

    static func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let diffSeconds = date.timeIntervalSince(now)
        let diffMinutes = Int(diffSeconds / 60)
        let diffHours = diffMinutes / 60

        if diffHours < 1 {
            return "in \(diffMinutes) \(diffMinutes == 1 ? "minute" : "minutes")"
        }
        if diffHours < 24 {
            return "in \(diffHours) \(diffHours == 1 ? "hour" : "hours")"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE 'at' h:mm a"
        return formatter.string(from: date)
    }
}
