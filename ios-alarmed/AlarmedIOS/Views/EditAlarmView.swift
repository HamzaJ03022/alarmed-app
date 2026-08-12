import SwiftUI

struct EditAlarmView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date
    @State private var label: String
    @State private var repeatDays: [String]
    @State private var questionCount: Int
    @State private var difficulty: String
    @State private var categories: [String]
    @State private var vibrate: Bool
    @State private var dismissalMode: String
    @State private var dismissPhrase: String

    @State private var showDeleteConfirm = false

    private let allDays: [(key: String, label: String)] = [
        ("mon", "M"), ("tue", "T"), ("wed", "W"), ("thu", "T"),
        ("fri", "F"), ("sat", "S"), ("sun", "S")
    ]
    private let difficultyOptions = ["easy", "medium", "hard"]
    private let categoryOptions: [(key: String, label: String)] = [
        ("math", "Math"), ("general", "General"), ("puzzle", "Puzzle")
    ]

    init(alarm: Alarm) {
        self.alarm = alarm
        let parts = alarm.time.split(separator: ":")
        var date = Date()
        if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
            date = Calendar.current.date(
                bySettingHour: h, minute: m, second: 0, of: date
            ) ?? date
        }
        _selectedDate = State(initialValue: date)
        _label = State(initialValue: alarm.label)
        _repeatDays = State(initialValue: alarm.repeatDays)
        _questionCount = State(initialValue: alarm.questionCount)
        _difficulty = State(initialValue: alarm.questionDifficulty)
        _categories = State(initialValue: alarm.questionCategories)
        _vibrate = State(initialValue: alarm.vibrate)
        _dismissalMode = State(initialValue: alarm.dismissalMode)
        _dismissPhrase = State(initialValue: alarm.dismissPhrase)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeCard
                    detailsCard
                    challengeCard
                    actionButtons
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .alert("Delete Alarm", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteAlarm(id: alarm.id)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this alarm?")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Label")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                TextField("Alarm label (optional)", text: $label)
                    .padding(16)
                    .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppColors.text)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .textCase(.uppercase)
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
                                        ? AppColors.text : AppColors.textSecondary
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    repeatDays.contains(day.key)
                                        ? AppColors.primary : AppColors.inputBackground,
                                    in: Circle()
                                )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vibrate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                Toggle("", isOn: $vibrate)
                    .tint(AppColors.primary)
                    .labelsHidden()
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
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
                                    difficulty == option ? AppColors.primary : AppColors.inputBackground,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Question Categories")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                HStack(spacing: 8) {
                    ForEach(categoryOptions, id: \.key) { cat in
                        let isSelected = categories.contains(cat.key)
                        let isOnly = categories.count == 1 && isSelected
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
                                .opacity(isOnly ? 0.5 : 1)
                        }
                        .disabled(isOnly)
                    }
                }
            }
        }
    }

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dismissal Phrase")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

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

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.body.bold())
                    .foregroundStyle(AppColors.text)
                    .frame(width: 56, height: 56)
                    .background(AppColors.error, in: RoundedRectangle(cornerRadius: 16))
            }

            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 16))
            }

            Button(action: saveChanges) {
                Text("Save")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
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

    private func saveChanges() {
        let time = TimeFormatter.formatTimeFromDate(selectedDate)
        viewModel.updateAlarm(id: alarm.id, with: PartialAlarmUpdate(
            time: time,
            label: label.trimmingCharacters(in: .whitespaces),
            repeatDays: repeatDays,
            questionCount: questionCount,
            questionDifficulty: difficulty,
            questionCategories: categories,
            vibrate: vibrate,
            dismissalMode: dismissalMode,
            dismissPhrase: dismissalMode == "phrase" ? dismissPhrase : ""
        ))
        dismiss()
    }
}

#Preview {
    EditAlarmView(alarm: Alarm(time: "07:30", label: "Morning", repeatDays: ["mon", "tue", "wed", "thu", "fri"]))
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
