import SwiftUI

struct QuestionCardView: View {
    let question: Question
    let questionNumber: Int
    let totalQuestions: Int
    let timeLimit: Int
    let onAnswer: (Bool) -> Void

    @State private var answer = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false
    @State private var timeLeft: Int
    @State private var timer: Timer?

    init(question: Question, questionNumber: Int, totalQuestions: Int, timeLimit: Int, onAnswer: @escaping (Bool) -> Void) {
        self.question = question
        self.questionNumber = questionNumber
        self.totalQuestions = totalQuestions
        self.timeLimit = timeLimit
        self.onAnswer = onAnswer
        _timeLeft = State(initialValue: timeLimit)
    }

    private var timerColor: Color {
        if timeLeft <= 10 { return AppColors.error }
        if timeLeft <= 30 { return Color(hex: "FFA500") }
        return AppColors.primary
    }

    var body: some View {
        VStack(spacing: 20) {
            headerRow
            timerBadge
            questionText
            answerArea
            if hasSubmitted { resultArea }
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 24, y: 8)
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: question.id) { reset() }
    }

    private var headerRow: some View {
        HStack {
            Text("Question \(questionNumber) of \(totalQuestions)")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(question.category.capitalized)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.primary, in: Capsule())
        }
    }

    private var timerBadge: some View {
        Text("\(timeLeft)s")
            .font(.title2.bold())
            .foregroundStyle(AppColors.text)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(timerColor, in: Capsule())
    }

    private var questionText: some View {
        Text(question.question)
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.text)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }

    @ViewBuilder
    private var answerArea: some View {
        if let options = question.options {
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        if !hasSubmitted {
                            answer = option
                            isCorrect = question.isAnswerCorrect(option)
                            hasSubmitted = true
                            timer?.invalidate()
                        }
                    } label: {
                        Text(option)
                            .font(.body)
                            .foregroundStyle(AppColors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(optionBackground(option), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(hasSubmitted)
                }
            }
        } else {
            VStack(spacing: 12) {
                TextField("Enter your answer...", text: $answer)
                    .padding(16)
                    .background(
                        hasSubmitted
                            ? (isCorrect ? AppColors.success.opacity(0.2) : AppColors.error.opacity(0.2))
                            : AppColors.buttonInactive,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hasSubmitted
                                ? (isCorrect ? AppColors.success : AppColors.error)
                                : AppColors.buttonBorder, lineWidth: 1)
                    )
                    .foregroundStyle(AppColors.text)
                    .disabled(hasSubmitted)
                    .keyboardType(question.numericAnswer != nil ? .numberPad : .default)

                if !hasSubmitted {
                    Button {
                        guard !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isCorrect = question.isAnswerCorrect(answer)
                        hasSubmitted = true
                        timer?.invalidate()
                    } label: {
                        Text("Submit")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var resultArea: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(isCorrect ? "Correct!" : "Incorrect!")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.text)
                if !isCorrect {
                    Text("The correct answer is: \(question.answer)")
                        .font(.caption)
                        .foregroundStyle(AppColors.text)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                isCorrect ? AppColors.success.opacity(0.2) : AppColors.error.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 16)
            )

            Button {
                onAnswer(isCorrect)
            } label: {
                Text(isCorrect ? "Continue" : "Next Question")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func optionBackground(_ option: String) -> Color {
        guard hasSubmitted else { return AppColors.buttonInactive }
        if option == answer {
            return isCorrect ? AppColors.success.opacity(0.2) : AppColors.error.opacity(0.2)
        }
        return AppColors.buttonInactive
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if timeLeft > 0 && !hasSubmitted {
                timeLeft -= 1
            } else if timeLeft == 0 && !hasSubmitted {
                hasSubmitted = true
                t.invalidate()
            } else {
                t.invalidate()
            }
        }
    }

    private func reset() {
        answer = ""
        hasSubmitted = false
        isCorrect = false
        timeLeft = timeLimit
        startTimer()
    }
}

#Preview {
    QuestionCardView(
        question: Question(
            id: "test",
            category: "math",
            difficulty: "easy",
            question: "What is 8 + 12?",
            answer: "20"
        ),
        questionNumber: 1,
        totalQuestions: 3,
        timeLimit: 90
    ) { _ in }
    .preferredColorScheme(.dark)
    .padding()
    .background(AppColors.background)
}
