import SwiftUI

struct AlarmRingingView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var correctAnswers = 0
    @State private var snoozeCount = 0
    @State private var completed = false
    @State private var selectedQuote = ""
    @State private var currentVolume: Double = 0.5
    @State private var alarmTime = ""

    private let timeLimit = 90

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if completed {
                MotivationalQuoteView(quote: selectedQuote) {
                    finishAlarm()
                }
            } else if questions.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else {
                VStack(spacing: 0) {
                    headerSection
                    questionSection
                    snoozeButton
                }
            }
        }
        .onAppear { startAlarm() }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(alarmTime)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)

            if viewModel.crescendoEnabled {
                VStack(spacing: 4) {
                    Text("Volume: \(Int(currentVolume * 100))%")
                        .font(.caption)
                        .foregroundStyle(AppColors.primary)
                    GeometryReader { geo in
                        Capsule()
                            .fill(AppColors.border)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.primary)
                                    .frame(width: geo.size.width * currentVolume)
                            }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 60)
            }
        }
        .padding(.top, 80)
    }

    private var questionSection: some View {
        Group {
            if currentQuestionIndex < questions.count {
                QuestionCardView(
                    question: questions[currentQuestionIndex],
                    questionNumber: correctAnswers + 1,
                    totalQuestions: alarm.questionCount,
                    timeLimit: timeLimit,
                    onAnswer: handleAnswer
                )
                .padding(.horizontal, 16)
                .padding(.top, 24)
            } else {
                VStack(spacing: 16) {
                    Text("Out of questions!")
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.text)
                    Text("Tap Start Over to continue the challenge.")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(24)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var snoozeButton: some View {
        Button(action: handleSnooze) {
            Text("Start Over (\(snoozeCount))")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.error, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppColors.error.opacity(0.3), radius: 12, y: 6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func startAlarm() {
        alarmTime = TimeFormatter.formatTime12h(alarm.time)
        questions = QuestionBank.getRandomQuestions(
            count: 50,
            difficulty: alarm.questionDifficulty,
            categories: alarm.questionCategories
        )
        let quotes = viewModel.quotes
        selectedQuote = quotes.randomElement() ?? "Rise and shine! Today is full of possibilities."

        AudioManager.shared.playAlarm(
            volume: viewModel.volume,
            crescendo: viewModel.crescendoEnabled
        )

        if viewModel.crescendoEnabled {
            startCrescendoMonitor()
        }
    }

    private func startCrescendoMonitor() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let vol = Double(AudioManager.shared.currentVolume)
            currentVolume = vol
            if vol >= viewModel.volume {
                timer.invalidate()
            }
        }
    }

    private func handleAnswer(_ isCorrect: Bool) {
        if isCorrect {
            HapticManager.successNotification()
            correctAnswers += 1
            if correctAnswers >= alarm.questionCount {
                AudioManager.shared.stop()
                completed = true
                return
            }
        } else {
            HapticManager.errorNotification()
        }
        currentQuestionIndex += 1
    }

    private func handleSnooze() {
        snoozeCount += 1
        currentQuestionIndex = 0
        correctAnswers = 0
        questions = QuestionBank.getRandomQuestions(
            count: 50,
            difficulty: alarm.questionDifficulty,
            categories: alarm.questionCategories
        )
        HapticManager.warningNotification()
    }

    private func finishAlarm() {
        viewModel.addHistory(AlarmHistory(
            alarmId: alarm.id,
            questionsAnswered: currentQuestionIndex + 1,
            questionsCorrect: correctAnswers,
            snoozeCount: snoozeCount
        ))
        viewModel.activeAlarmId = nil
    }
}

#Preview {
    AlarmRingingView(alarm: Alarm(
        time: "07:30",
        label: "Morning Wake Up",
        questionCount: 3,
        questionDifficulty: "medium"
    ))
    .environment(AlarmsViewModel())
    .preferredColorScheme(.dark)
}
