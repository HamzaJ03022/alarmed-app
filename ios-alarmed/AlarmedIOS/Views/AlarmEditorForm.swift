import SwiftUI

/// Editable alarm fields shared by Create and Edit. Saving still happens in
/// the owning screen through the same view-model calls as before.
struct AlarmDraft {
    var date: Date = Date()
    var label: String = ""
    var repeatDays: [String] = []
    var questionCount: Int = 3
    var difficulty: String = "medium"
    var categories: [String] = ["math", "general", "puzzle"]
    var vibrate: Bool = true
    var dismissalMode: String = "questions"
    var dismissPhrase: String = ""
    var sound: String = AlarmSound.defaultID

    static let phraseMinLength = 10
    static let phraseMaxLength = 100

    var time: String { TimeFormatter.formatTimeFromDate(date) }
    var trimmedLabel: String { label.trimmingCharacters(in: .whitespaces) }
    var phraseIsValid: Bool {
        dismissalMode == "questions" || dismissPhrase.count >= Self.phraseMinLength
    }
    var savedPhrase: String { dismissalMode == "phrase" ? dismissPhrase : "" }

    init() {}

    init(alarm: Alarm) {
        let parts = alarm.time.split(separator: ":")
        var date = Date()
        if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
            date = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: date) ?? date
        }
        self.date = date
        label = alarm.label
        repeatDays = alarm.repeatDays
        questionCount = alarm.questionCount
        difficulty = alarm.questionDifficulty
        categories = alarm.questionCategories
        vibrate = alarm.vibrate
        dismissalMode = alarm.dismissalMode
        dismissPhrase = alarm.dismissPhrase
        sound = alarm.sound
    }
}

/// The scrollable Create/Edit form: time focus, alarm details, challenge
/// tiles, sound & vibration, and an optional delete row.
struct AlarmEditorForm: View {
    @Binding var draft: AlarmDraft
    @Binding var showSoundPicker: Bool
    var onDelete: (() -> Void)? = nil

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 72
    @FocusState private var focusedField: Field?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Field { case label, phrase }

    private static let weekdays: Set<String> = ["mon", "tue", "wed", "thu", "fri"]
    private static let weekends: Set<String> = ["sat", "sun"]
    private let difficultyOptions: [(id: String, label: String)] = [
        ("easy", "Easy"), ("medium", "Medium"), ("hard", "Hard")
    ]
    private let categoryOptions: [(key: String, label: String)] = [
        ("math", "Math"), ("general", "General"), ("puzzle", "Puzzle")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                timeSection
                alarmSection
                challengeSection
                soundSection
                if let onDelete {
                    deleteSection(onDelete)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(AppColors.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
                    .tint(AppColors.primary)
            }
        }
    }

    // MARK: - Time (the focus)

    private var heroTime: (main: String, suffix: String) { ClockParts.split(draft.time) }

    private var timeSection: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(spacing: Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(heroTime.main)
                        .font(.system(size: heroSize, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.text)
                        .contentTransition(.numericText())
                    Text(heroTime.suffix)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .animation(reduceMotion ? nil : .snappy, value: draft.time)
                .accessibilityElement(children: .combine)

                if let next = TimeFormatter.getNextAlarmTime(time: draft.time, repeatDays: draft.repeatDays) {
                    Text("Rings in \(ClockParts.countdown(to: next, from: context.date)) · \(ClockParts.dayDescription(for: next, now: context.date))")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.primary)
                        .accessibilityLabel("Rings in \(ClockParts.spokenCountdown(to: next, from: context.date))")
                }

                DatePicker("Alarm time", selection: $draft.date, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .sensoryFeedback(.selection, trigger: draft.time)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xs)
        }
    }

    // MARK: - Alarm details

    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Alarm")
            SectionCard {
                HStack(spacing: Spacing.sm) {
                    IconTile(systemName: "tag.fill")
                    TextField(
                        "",
                        text: $draft.label,
                        prompt: Text("Label (optional)").foregroundStyle(AppColors.inactive)
                    )
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColors.text)
                    .tint(AppColors.primary)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .label)
                    .accessibilityLabel("Alarm label")
                    if !draft.label.isEmpty {
                        Button {
                            draft.label = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.inactive)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Clear label")
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 56)

                RowDivider()

                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        IconTile(systemName: "repeat")
                        Text("Repeat")
                            .font(AppFont.rowTitle)
                            .foregroundStyle(AppColors.text)
                        Spacer()
                        Text(repeatSummary)
                            .font(AppFont.rowDetail.weight(.medium))
                            .foregroundStyle(draft.repeatDays.isEmpty ? AppColors.textSecondary : AppColors.primary)
                            .contentTransition(.opacity)
                    }
                    .accessibilityElement(children: .combine)

                    DaySelector(selection: $draft.repeatDays)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Spacing.xs) { shortcutChips }
                        ScrollView(.horizontal) {
                            HStack(spacing: Spacing.xs) { shortcutChips }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(Spacing.md)
            }
        }
    }

    @ViewBuilder
    private var shortcutChips: some View {
        ChipButton(title: "Weekdays", isSelected: Set(draft.repeatDays) == Self.weekdays && draft.repeatDays.count == 5) {
            draft.repeatDays = ["mon", "tue", "wed", "thu", "fri"]
        }
        ChipButton(title: "Every day", isSelected: draft.repeatDays.count == 7) {
            draft.repeatDays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
        }
        ChipButton(title: "Weekends", isSelected: Set(draft.repeatDays) == Self.weekends && draft.repeatDays.count == 2) {
            draft.repeatDays = ["sat", "sun"]
        }
    }

    private var repeatSummary: String {
        TimeFormatter.formatRepeatDays(draft.repeatDays)
    }

    // MARK: - Wake-up challenge

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Wake-up challenge", detail: "How you'll prove you're awake")

            HStack(alignment: .top, spacing: Spacing.sm) {
                SelectionTile(
                    icon: "brain.head.profile",
                    title: "Questions",
                    subtitle: "Solve quick math, trivia and puzzles",
                    isSelected: draft.dismissalMode == "questions"
                ) { selectMode("questions") }
                SelectionTile(
                    icon: "character.cursor.ibeam",
                    title: "Type a Phrase",
                    subtitle: "Type your own phrase exactly",
                    isSelected: draft.dismissalMode == "phrase"
                ) { selectMode("phrase") }
            }
            .fixedSize(horizontal: false, vertical: true)

            Group {
                if draft.dismissalMode == "questions" {
                    questionsConfig
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    phraseConfig
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.top, Spacing.xxs)
        }
    }

    private func selectMode(_ mode: String) {
        guard draft.dismissalMode != mode else { return }
        focusedField = nil
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86)) {
            draft.dismissalMode = mode
        }
    }

    private var questionsConfig: some View {
        SectionCard {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Questions")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColors.text)
                    Text("Answer all to stop the alarm")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                QuantityStepper(value: $draft.questionCount, range: 1...5) {
                    "\($0) \($0 == 1 ? "question" : "questions")"
                }
            }
            .padding(Spacing.md)

            RowDivider()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Difficulty")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColors.text)
                SegmentedPicker(options: difficultyOptions, selection: $draft.difficulty)
                    .accessibilityLabel("Difficulty")
            }
            .padding(Spacing.md)

            RowDivider()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Topics")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColors.text)
                HStack(spacing: Spacing.xs) {
                    ForEach(categoryOptions, id: \.key) { cat in
                        let isSelected = draft.categories.contains(cat.key)
                        let isLastRemaining = isSelected && draft.categories.count == 1
                        ChipButton(title: cat.label, isSelected: isSelected, isLocked: isLastRemaining) {
                            if isSelected && draft.categories.count > 1 {
                                draft.categories.removeAll { $0 == cat.key }
                            } else if !isSelected {
                                draft.categories.append(cat.key)
                            }
                        }
                    }
                }
                Text(draft.categories.count == 1 ? "At least one topic stays on." : "Mixed from the topics you pick.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.inactive)
            }
            .padding(Spacing.md)
        }
    }

    private var phraseTooShort: Bool {
        !draft.dismissPhrase.isEmpty && draft.dismissPhrase.count < AlarmDraft.phraseMinLength
    }

    private var phraseConfig: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Your phrase")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text("\(draft.dismissPhrase.count)/\(AlarmDraft.phraseMaxLength)")
                        .font(AppFont.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(phraseTooShort ? AppColors.error : AppColors.inactive)
                        .accessibilityLabel("\(draft.dismissPhrase.count) of \(AlarmDraft.phraseMaxLength) characters")
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draft.dismissPhrase)
                        .font(.body)
                        .foregroundStyle(AppColors.text)
                        .tint(AppColors.primary)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .phrase)
                        .frame(minHeight: 96)
                        .padding(Spacing.xs)
                        .accessibilityLabel("Dismissal phrase")
                        .onChange(of: draft.dismissPhrase) { _, newValue in
                            if newValue.count > AlarmDraft.phraseMaxLength {
                                draft.dismissPhrase = String(newValue.prefix(AlarmDraft.phraseMaxLength))
                            }
                        }
                    if draft.dismissPhrase.isEmpty {
                        Text("e.g. I'm getting up to make today count")
                            .font(.body)
                            .foregroundStyle(AppColors.inactive)
                            .padding(.horizontal, Spacing.sm + 1)
                            .padding(.vertical, Spacing.md)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .strokeBorder(
                            phraseTooShort ? AppColors.error.opacity(0.7)
                                : (focusedField == .phrase ? AppColors.primary.opacity(0.7) : Color.clear),
                            lineWidth: 1
                        )
                )

                if phraseTooShort {
                    InlineErrorText(message: "Phrase must be at least \(AlarmDraft.phraseMinLength) characters")
                } else {
                    Text("You'll type this exactly (case-sensitive) to stop the alarm.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.md)
        }
    }

    // MARK: - Sound & vibration

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Sound & vibration")
            SectionCard {
                NavigationRow(
                    icon: "music.note",
                    title: "Sound",
                    value: AlarmSound.sound(forID: draft.sound).name
                ) {
                    focusedField = nil
                    showSoundPicker = true
                }
                RowDivider(leadingInset: 58)
                ToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Vibrate", isOn: $draft.vibrate)
                RowDivider(leadingInset: 58)
                InfoRow(
                    icon: "speaker.wave.3.fill",
                    iconTint: AppColors.textSecondary,
                    title: "Volume: always max",
                    subtitle: "Locked until the challenge is solved"
                )
            }
        }
    }

    // MARK: - Delete (edit only)

    private func deleteSection(_ onDelete: @escaping () -> Void) -> some View {
        SectionCard {
            Button(role: .destructive, action: onDelete) {
                Text("Delete Alarm")
                    .font(AppFont.rowTitleEmphasis)
                    .foregroundStyle(AppColors.error)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(RowButtonStyle())
        }
        .padding(.top, Spacing.xs)
    }
}

/// Pinned save bar: full-width primary button above the home indicator,
/// with a soft fade so content scrolls cleanly underneath.
struct SaveBar: View {
    let title: String
    let isEnabled: Bool
    var disabledHint: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if !isEnabled, let disabledHint {
                Text(disabledHint)
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            Button(action: action) {
                Text(title)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isEnabled)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .frame(maxWidth: .infinity)
        .background {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [AppColors.background.opacity(0), AppColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                AppColors.background
            }
            .padding(.top, -20)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
