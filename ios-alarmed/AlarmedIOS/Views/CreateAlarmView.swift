import SwiftUI

struct CreateAlarmView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var label = ""
    @State private var repeatDays: [String] = []
    @State private var questionCount = 3
    @State private var difficulty = "medium"
    @State private var categories: [String] = ["math", "general", "puzzle"]
    @State private var vibrate = true
    @State private var dismissalMode: String = "questions"
    @State private var dismissPhrase = ""

    private let allDays: [(key: String, label: String)] = [
        ("mon", "M"), ("tue", "T"), ("wed", "W"), ("thu", "T"),
        ("fri", "F"), ("sat", "S"), ("sun", "S")
    ]
    private let difficultyOptions = ["easy", "medium", "hard"]
    private let categoryOptions: [(key: String, label: String)] = [
        ("math", "Math"), ("general", "General"), ("puzzle", "Puzzle")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeCard
                    detailsCard
                    challengeCard
                    buttonsRow
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Create Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var timeCard: some View {
        VStack(spacing: 16) {
            Text("Set Time")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 180)
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Alarm Details")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.text)

            TextField("Alarm label (optional)", text: $label)
                .padding(16)
                .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(AppColors.text)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Repeat Days")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
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
            }
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Wake-Up Challenge")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.text)

            VStack(alignment: .leading, spacing: 12) {
                Text("Dismissal Method")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
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
            }

            if dismissalMode == "questions" {
                questionsSection
            } else {
                phraseSection
            }
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Number of Questions")
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
                Text("Difficulty")
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
                Text("Question Categories")
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

    private var buttonsRow: some View {
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
    }

    private var phraseIsValid: Bool {
        dismissalMode == "questions" || dismissPhrase.count >= 10
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
            dismissPhrase: dismissalMode == "phrase" ? dismissPhrase : ""
        )
        viewModel.addAlarm(alarm)
        dismiss()
    }
}

#Preview {
    CreateAlarmView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
