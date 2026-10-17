import SwiftUI

struct CreateAlarmView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var label = ""
    @State private var repeatEnabled = false
    @State private var repeatDays: [String] = []
    @State private var questionCount = 3
    @State private var difficulty = "medium"
    @State private var categories: [String] = ["math", "general", "puzzle"]
    @State private var vibrate = true
    @State private var dismissalMode: String = "questions"
    @State private var dismissPhrase = ""
    @State private var sound = AlarmSound.defaultID
    @State private var didApplyDefaults = false

    @State private var showSoundPicker = false

    private let allDays: [(key: String, label: String)] = [
        ("mon", "M"), ("tue", "T"), ("wed", "W"), ("thu", "T"),
        ("fri", "F"), ("sat", "S"), ("sun", "S")
    ]
    private let difficultyOptions = ["easy", "medium", "hard"]
    private let categoryOptions: [(key: String, label: String)] = [
        ("math", "Math"), ("general", "General"), ("puzzle", "Puzzle")
    ]
    private static let weekdays: Set<String> = ["mon", "tue", "wed", "thu", "fri"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    timeSection
                    detailsSection
                    challengeSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppColors.background)
            .navigationDestination(isPresented: $showSoundPicker) {
                SoundPickerView(selectedSoundId: $sound)
            }
            .onAppear(perform: applyOnboardingDefaults)
            .navigationTitle("Create Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
    }

    // MARK: - Time (primary action)

    private var heroTime: (main: String, suffix: String) {
        let formatted = TimeFormatter.formatTime12h(TimeFormatter.formatTimeFromDate(selectedDate))
        let parts = formatted.split(separator: " ", omittingEmptySubsequences: false)
        return (parts.first.map(String.init) ?? formatted, parts.count > 1 ? String(parts[1]) : "")
    }

    private var timeSection: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(heroTime.main)
                    .font(.system(size: 60, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.text)
                Text(heroTime.suffix)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, 12)

            Text("Drag the wheel to set your alarm time")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 160)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Details")

            VStack(alignment: .leading, spacing: 4) {
                TextField("Alarm label (optional)", text: $label)
                    .padding(16)
                    .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppColors.text)
            }

            divider

            repeatSection

            divider

            Button {
                showSoundPicker = true
            } label: {
                HStack {
                    Text("Sound")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text(AlarmSound.sound(forID: sound).name)
                        .foregroundStyle(AppColors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            divider

            HStack {
                Text("Vibrate")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                Spacer()
                Toggle("", isOn: $vibrate)
                    .tint(AppColors.primary)
                    .labelsHidden()
            }
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text(repeatSummary)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $repeatEnabled)
                    .tint(AppColors.primary)
                    .labelsHidden()
                    .onChange(of: repeatEnabled) { _, isOn in
                        if isOn, repeatDays.isEmpty {
                            repeatDays = ["mon", "tue", "wed", "thu", "fri"]
                        } else if !isOn {
                            repeatDays = []
                        }
                    }
            }

            if repeatEnabled {
                HStack(spacing: 8) {
                    quickRepeatChip("Weekdays", selected: Set(repeatDays) == Self.weekdays) {
                        repeatDays = ["mon", "tue", "wed", "thu", "fri"]
                    }
                    quickRepeatChip("Every day", selected: repeatDays.count == 7) {
                        repeatDays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    ForEach(allDays, id: \.key) { day in
                        Button {
                            if repeatDays.contains(day.key) {
                                repeatDays.removeAll { $0 == day.key }
                            } else {
                                repeatDays.append(day.key)
                            }
                        } label: {
                            Text(day.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    repeatDays.contains(day.key)
                                        ? AppColors.text
                                        : AppColors.textSecondary
                                )
                                .frame(width: 40, height: 40)
                                .background(
                                    repeatDays.contains(day.key)
                                        ? AppColors.primary
                                        : AppColors.inputBackground,
                                    in: Circle()
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var repeatSummary: String {
        if !repeatEnabled || repeatDays.isEmpty { return "One-time alarm" }
        return "Repeats " + TimeFormatter.formatRepeatDays(repeatDays).lowercased()
    }

    private func quickRepeatChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(selected ? AppColors.text : AppColors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected ? AppColors.primary.opacity(0.35) : AppColors.primary.opacity(0.12),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Challenge

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Wake-Up Challenge")

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(["questions", "phrase"], id: \.self) { mode in
                        Button {
                            dismissalMode = mode
                        } label: {
                            Text(mode == "questions" ? "Questions" : "Type a Phrase")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(
                                    dismissalMode == mode ? AppColors.text : AppColors.textSecondary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    dismissalMode == mode
                                        ? AppColors.primary
                                        : AppColors.inputBackground,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                    }
                }
                Text(dismissalMode == "questions"
                     ? "Answer quick math and trivia questions to turn the alarm off."
                     : "Type your own phrase exactly to turn the alarm off.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            if dismissalMode == "questions" {
                questionsSection
            } else {
                phraseSection
            }
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("How many questions")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                HStack(spacing: 0) {
                    Button {
                        questionCount = max(1, questionCount - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.bold())
                            .foregroundStyle(AppColors.text)
                            .frame(width: 52, height: 52)
                            .background(AppColors.inputBackground, in: Circle())
                    }
                    Text("\(questionCount)")
                        .font(.title.bold())
                        .monospacedDigit()
                        .foregroundStyle(AppColors.text)
                        .frame(minWidth: 60)
                    Button {
                        questionCount = min(5, questionCount + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundStyle(AppColors.text)
                            .frame(width: 52, height: 52)
                            .background(AppColors.inputBackground, in: Circle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("How hard")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                HStack(spacing: 10) {
                    ForEach(difficultyOptions, id: \.self) { option in
                        Button {
                            difficulty = option
                        } label: {
                            Text(option.capitalized)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(
                                    difficulty == option ? AppColors.text : AppColors.textSecondary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    difficulty == option
                                        ? AppColors.primary
                                        : AppColors.inputBackground,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Question topics")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                HStack(spacing: 8) {
                    ForEach(categoryOptions, id: \.key) { cat in
                        let isSelected = categories.contains(cat.key)
                        let isLastRemaining = categories.count == 1 && isSelected
                        Button {
                            if isSelected && categories.count > 1 {
                                categories.removeAll { $0 == cat.key }
                            } else if !isSelected {
                                categories.append(cat.key)
                            }
                        } label: {
                            Text(cat.label)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(
                                    isSelected ? AppColors.text : AppColors.textSecondary
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    isSelected ? AppColors.primary : AppColors.inputBackground,
                                    in: Capsule()
                                )
                                .opacity(isLastRemaining ? 0.5 : 1)
                        }
                        .disabled(isLastRemaining)
                    }
                }
            }
        }
    }

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dismissal Phrase")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.text)

            TextEditor(text: $dismissPhrase)
                .font(.body)
                .foregroundStyle(AppColors.text)
                .frame(minHeight: 80)
                .padding(12)
                .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if dismissPhrase.isEmpty {
                        Text("e.g. I want to wake up so I can get to work on time and not be late")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: dismissPhrase) { _, newValue in
                    if newValue.count > 100 {
                        dismissPhrase = String(newValue.prefix(100))
                    }
                }

            Text("\(dismissPhrase.count)/100")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if !dismissPhrase.isEmpty && dismissPhrase.count < 10 {
                Text("Phrase must be at least 10 characters")
                    .font(.caption)
                    .foregroundStyle(AppColors.error)
            }

            Text("You'll need to type this phrase exactly (case-sensitive) to dismiss the alarm.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(2)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 16))
            }
            Button(action: saveAlarm) {
                Text("Save Alarm")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        phraseIsValid ? AppColors.primary : AppColors.primary.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .disabled(!phraseIsValid)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(AppColors.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1)
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(AppColors.textSecondary)
    }

    private var phraseIsValid: Bool {
        dismissalMode == "questions" || dismissPhrase.count >= 10
    }

    private func applyOnboardingDefaults() {
        guard !didApplyDefaults else { return }
        didApplyDefaults = true
        dismissalMode = viewModel.defaultChallengeMode
        dismissPhrase = viewModel.onboardingPhrase
    }

    private func saveAlarm() {
        let time = TimeFormatter.formatTimeFromDate(selectedDate)
        let alarm = Alarm(
            time: time,
            label: label.trimmingCharacters(in: .whitespaces),
            repeatDays: repeatDays,
            questionCount: questionCount,
            questionDifficulty: difficulty,
            questionCategories: categories,
            vibrate: vibrate,
            dismissalMode: dismissalMode,
            dismissPhrase: dismissalMode == "phrase" ? dismissPhrase : "",
            sound: sound
        )
        viewModel.addAlarm(alarm)
        viewModel.saveConfirmationMessage =
            "Alarm saved \u{2022} rings at \(TimeFormatter.formatTime12h(time))"
        dismiss()
    }
}

#Preview {
    CreateAlarmView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
