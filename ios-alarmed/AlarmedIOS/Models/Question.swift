import Foundation

struct Question: Identifiable, Equatable {
    let id: String
    let category: String
    let difficulty: String
    let question: String
    let options: [String]?
    let answer: String

    init(
        id: String,
        category: String,
        difficulty: String,
        question: String,
        options: [String]? = nil,
        answer: String
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.question = question
        self.options = options
        self.answer = answer
    }

    var isMultipleChoice: Bool { options != nil }
    var numericAnswer: Int? { Int(answer) }

    func isAnswerCorrect(_ userAnswer: String) -> Bool {
        let trimmed = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = answer.lowercased()
        return trimmed == correct
    }
}
