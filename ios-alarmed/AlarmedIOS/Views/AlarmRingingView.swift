import SwiftUI

struct AlarmRingingView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var correctAnswers = 0
    @State private var snoozeCount = 0
    @State private var completed = false
    @State private var selectedQuote = ""
    @State private var alarmTime = ""

    private let timeLimit = 90

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if completed {
                MotivationalQuoteView(quote: selectedQuote) {
                    finishAlarm()
                }
            } else if alarm.dismissalMode == "phrase" {
                VStack(spacing: 0) {
                    headerSection
                    PhraseChallengeView(
                        phrase: alarm.dismissPhrase,
                        onCorrect: handlePhraseCorrect,
                        onSnooze: handleSnooze,
                        snoozeCount: snoozeCount
                    )
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
        .background {
            SystemVolumeLockHost()
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onAppear { startAlarm() }
        .onDisappear {
            SystemVolumeLock.shared.disengage()
            CrashGuard.end(.challenge)
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving the app pauses in-app audio (the re-ring backups keep
            // ringing on the lock screen); coming back resumes full volume.
            switch phase {
            case .active where !completed:
                startRinging()
            case .background:
                SystemVolumeLock.shared.pause()
                CrashGuard.end(.challenge)
            default:
                break
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(alarmTime)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)

            Label("Volume locked at max until solved", systemImage: "speaker.wave.3.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 4)
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
        if alarm.dismissalMode == "questions" {
            questions = QuestionBank.getRandomQuestions(
                count: 50,
                difficulty: alarm.questionDifficulty,
                categories: alarm.questionCategories
            )
        }
        let quotes = viewModel.quotes
        selectedQuote = quotes.randomElement() ?? "Rise and shine! Today is full of possibilities."

        startRinging()
    }

    /// A real alarm always rings at full volume: no fade-in, no in-app volume
    /// cap, no mute — and the device volume is locked at max until solved.
    private func startRinging() {
        guard !completed else { return }
        CrashGuard.begin(.challenge)
        AudioManager.shared.playAlarm(soundId: alarm.sound, vibrate: viewModel.vibrationEnabled && alarm.vibrate)
        SystemVolumeLock.shared.engage()
    }

    /// The only way the alarm stops: questions answered or phrase completed.
    private func challengeSolved() {
        AudioManager.shared.stop()
        SystemVolumeLock.shared.disengage()
        CrashGuard.end(.challenge)
        viewModel.challengeSolved(alarm)
        completed = true
    }

    private func handleAnswer(_ isCorrect: Bool) {
        if isCorrect {
            HapticManager.successNotification()
            correctAnswers += 1
            if correctAnswers >= alarm.questionCount {
                challengeSolved()
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
        if alarm.dismissalMode == "questions" {
            questions = QuestionBank.getRandomQuestions(
                count: 50,
                difficulty: alarm.questionDifficulty,
                categories: alarm.questionCategories
            )
        }
        HapticManager.warningNotification()
    }

    private func handlePhraseCorrect() {
        HapticManager.successNotification()
        challengeSolved()
    }

    private func finishAlarm() {
        viewModel.addHistory(AlarmHistory(
            alarmId: alarm.id,
            questionsAnswered: alarm.dismissalMode == "phrase" ? 0 : currentQuestionIndex + 1,
            questionsCorrect: alarm.dismissalMode == "phrase" ? 0 : correctAnswers,
            snoozeCount: snoozeCount
        ))
        // One-time alarms auto-disable after ringing so they don't stay
        // displayed as armed when they will never fire again.
        if alarm.repeatDays.isEmpty {
            viewModel.updateAlarm(id: alarm.id, with: PartialAlarmUpdate(isActive: false))
        }
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
