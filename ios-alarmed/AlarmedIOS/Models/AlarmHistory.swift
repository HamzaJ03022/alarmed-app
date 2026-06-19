import Foundation

struct AlarmHistory: Identifiable, Codable, Equatable {
    var id: String
    var alarmId: String
    var date: String
    var wakeUpTime: String
    var questionsAnswered: Int
    var questionsCorrect: Int
    var snoozeCount: Int
    var dismissed: Bool

    init(
        id: String = UUID().uuidString,
        alarmId: String,
        date: String = ISO8601DateFormatter().string(from: Date()),
        wakeUpTime: String = ISO8601DateFormatter().string(from: Date()),
        questionsAnswered: Int = 0,
        questionsCorrect: Int = 0,
        snoozeCount: Int = 0,
        dismissed: Bool = false
    ) {
        self.id = id
        self.alarmId = alarmId
        self.date = date
        self.wakeUpTime = wakeUpTime
        self.questionsAnswered = questionsAnswered
        self.questionsCorrect = questionsCorrect
        self.snoozeCount = snoozeCount
        self.dismissed = dismissed
    }
}
