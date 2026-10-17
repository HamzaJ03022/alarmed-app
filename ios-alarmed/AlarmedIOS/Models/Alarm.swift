import Foundation

typealias RepeatDay = String
typealias QuestionDifficulty = String
typealias QuestionCategory = String
typealias DismissalMode = String

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
    var dismissalMode: DismissalMode
    var dismissPhrase: String
    /// Id of the alarm tone in `AlarmSound` (chosen in the sound picker).
    var sound: String

    init(
        id: String = UUID().uuidString,
        time: String,
        label: String = "",
        isActive: Bool = true,
        repeatDays: [RepeatDay] = [],
        questionCount: Int = 3,
        questionDifficulty: QuestionDifficulty = "medium",
        questionCategories: [QuestionCategory] = ["math", "general", "puzzle"],
        vibrate: Bool = true,
        dismissalMode: DismissalMode = "questions",
        dismissPhrase: String = "",
        sound: String = AlarmSound.defaultID
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
        self.dismissalMode = dismissalMode
        self.dismissPhrase = dismissPhrase
        self.sound = sound
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        time = try container.decode(String.self, forKey: .time)
        label = try container.decode(String.self, forKey: .label)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        repeatDays = try container.decode([RepeatDay].self, forKey: .repeatDays)
        questionCount = try container.decode(Int.self, forKey: .questionCount)
        questionDifficulty = try container.decode(QuestionDifficulty.self, forKey: .questionDifficulty)
        questionCategories = try container.decode([QuestionCategory].self, forKey: .questionCategories)
        vibrate = try container.decode(Bool.self, forKey: .vibrate)
        dismissalMode = try container.decode(DismissalMode.self, forKey: .dismissalMode)
        dismissPhrase = try container.decode(String.self, forKey: .dismissPhrase)
        // Alarms saved before the sound picker have no key — they get the
        // default tone instead of failing the whole decode.
        sound = try container.decodeIfPresent(String.self, forKey: .sound) ?? AlarmSound.defaultID
    }
}
