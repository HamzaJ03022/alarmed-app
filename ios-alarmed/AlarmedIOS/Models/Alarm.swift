import Foundation

typealias RepeatDay = String
typealias QuestionDifficulty = String
typealias QuestionCategory = String

struct Alarm: Identifiable, Codable, Equatable {
    var id: String
    var time: String
    var label: String
    var isActive: Bool
    var repeatDays: [RepeatDay]
    var questionCount: Int
    var questionDifficulty: QuestionDifficulty
    var questionCategories: [QuestionCategory]
    var vibrate: Bool

    init(
        id: String = UUID().uuidString,
        time: String,
        label: String = "",
        isActive: Bool = true,
        repeatDays: [RepeatDay] = [],
        questionCount: Int = 3,
        questionDifficulty: QuestionDifficulty = "medium",
        questionCategories: [QuestionCategory] = ["math", "general", "puzzle"],
        vibrate: Bool = true
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.isActive = isActive
        self.repeatDays = repeatDays
        self.questionCount = questionCount
        self.questionDifficulty = questionDifficulty
        self.questionCategories = questionCategories
        self.vibrate = vibrate
    }
}
