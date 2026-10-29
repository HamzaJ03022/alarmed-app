import SwiftUI

/// Compact alarm card for the Alarms list. Tap opens Edit; the switch on
/// the right enables/disables the alarm through the view model as before.
struct AlarmItemView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showEditAlarm = false
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 36

    private var isOn: Bool { alarm.isActive }
    private var time: (main: String, suffix: String) { ClockParts.split(alarm.time) }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button {
                showEditAlarm = true
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(time.main)
                            .font(AppFont.clock(timeSize))
                            .monospacedDigit()
                            .foregroundStyle(isOn ? AppColors.text : AppColors.inactive)
                        Text(time.suffix)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isOn ? AppColors.textSecondary : AppColors.inactive)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isOn ? AppColors.text : AppColors.inactive)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    AlarmMetaLine(alarm: alarm, isOn: isOn)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.98))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AlarmAccessibility.label(for: alarm))
            .accessibilityHint("Opens alarm settings")

            Toggle("Alarm \(time.main) \(time.suffix)", isOn: Binding(
                get: { alarm.isActive },
                set: { _ in viewModel.toggleAlarm(id: alarm.id) }
            ))
            .labelsHidden()
            .tint(AppColors.primary)
            .sensoryFeedback(.impact(weight: .light), trigger: alarm.isActive)
        }
        .padding(.horizontal, Spacing.md + 2)
        .padding(.vertical, Spacing.md)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: alarm.isActive)
        .sheet(isPresented: $showEditAlarm) {
            EditAlarmView(alarm: alarm)
        }
    }
}

/// Day letters + challenge tag line, shared by the card and the hero.
struct AlarmMetaLine: View {
    let alarm: Alarm
    let isOn: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.xs) {
                repeatView
                dot
                ChallengeTag(alarm: alarm, isOn: isOn)
            }
            VStack(alignment: .leading, spacing: 4) {
                repeatView
                ChallengeTag(alarm: alarm, isOn: isOn)
            }
        }
    }

    @ViewBuilder
    private var repeatView: some View {
        if alarm.repeatDays.isEmpty {
            Text("Once")
                .font(AppFont.tag)
                .foregroundStyle(isOn ? AppColors.textSecondary : AppColors.inactive)
        } else {
            HStack(spacing: 3) {
                ForEach(DaySelector.days, id: \.key) { day in
                    let included = alarm.repeatDays.contains(day.key)
                    Text(day.short)
                        .font(.caption2.weight(included ? .bold : .medium))
                        .foregroundStyle(
                            included
                                ? (isOn ? AppColors.primary : AppColors.textSecondary)
                                : AppColors.inactive.opacity(0.7)
                        )
                        .frame(minWidth: 10)
                }
            }
        }
    }

    private var dot: some View {
        Circle()
            .fill(AppColors.inactive)
            .frame(width: 3, height: 3)
    }
}

/// Small "3 questions" / "Phrase" tag.
struct ChallengeTag: View {
    let alarm: Alarm
    let isOn: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: alarm.dismissalMode == "phrase" ? "character.cursor.ibeam" : "brain.head.profile")
                .font(.caption2.weight(.semibold))
            Text(AlarmAccessibility.challengeText(for: alarm))
                .font(AppFont.tag)
        }
        .foregroundStyle(isOn ? AppColors.textSecondary : AppColors.inactive)
        .lineLimit(1)
    }
}

enum AlarmAccessibility {
    static func challengeText(for alarm: Alarm) -> String {
        alarm.dismissalMode == "phrase"
            ? "Phrase"
            : "\(alarm.questionCount) \(alarm.questionCount == 1 ? "question" : "questions")"
    }

    static func label(for alarm: Alarm) -> String {
        let time = TimeFormatter.formatTime12h(alarm.time)
        let label = alarm.label.isEmpty ? "" : ", \(alarm.label)"
        let repeatText = TimeFormatter.formatRepeatDays(alarm.repeatDays)
        let state = alarm.isActive ? "On" : "Off"
        return "\(time)\(label), \(repeatText), \(challengeText(for: alarm)), \(state)"
    }
}

#Preview {
    VStack(spacing: 10) {
        AlarmItemView(alarm: Alarm(
            time: "07:30",
            label: "Morning Wake Up",
            repeatDays: ["mon", "tue", "wed", "thu", "fri"],
            questionCount: 3,
            questionDifficulty: "medium"
        ))
        AlarmItemView(alarm: Alarm(time: "22:15", label: "", isActive: false))
    }
    .environment(AlarmsViewModel())
    .preferredColorScheme(.dark)
    .padding()
    .background(AppColors.background)
}
