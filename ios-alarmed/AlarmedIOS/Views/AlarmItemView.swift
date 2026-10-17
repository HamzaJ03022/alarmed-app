import SwiftUI

struct AlarmItemView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showEditAlarm = false

    private var nextAlarmText: String {
        guard alarm.isActive,
              let nextDate = TimeFormatter.getNextAlarmTime(
                time: alarm.time,
                repeatDays: alarm.repeatDays
              ) else { return "" }
        return TimeFormatter.formatRelativeTime(nextDate)
    }

    /// Clock-style time, e.g. ("7:30", "AM")
    private var displayTime: (main: String, suffix: String) {
        let formatted = TimeFormatter.formatTime12h(alarm.time)
        let parts = formatted.split(separator: " ", omittingEmptySubsequences: false)
        return (parts.first.map(String.init) ?? formatted, parts.count > 1 ? String(parts[1]) : "")
    }

    private var scheduleLine: String {
        let repeatText = TimeFormatter.formatRepeatDays(alarm.repeatDays)
        let challengeText = alarm.dismissalMode == "phrase"
            ? "Type a phrase"
            : "\(alarm.questionCount) \(alarm.questionCount == 1 ? "question" : "questions") \u{2022} \(alarm.questionDifficulty.capitalized)"
        return "\(repeatText) \u{2022} \(challengeText)"
    }

    private var timeColor: Color { alarm.isActive ? AppColors.text : AppColors.inactive }
    private var detailColor: Color { alarm.isActive ? AppColors.textSecondary : AppColors.inactive }

    var body: some View {
        Button {
            showEditAlarm = true
        } label: {
            HStack(alignment: .center, spacing: 16) {
                // Time: the scannable anchor of the row
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(displayTime.main)
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .monospacedDigit()
                    Text(displayTime.suffix)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(alarm.isActive ? AppColors.primary : AppColors.inactive)
                }
                .foregroundStyle(timeColor)

                VStack(alignment: .leading, spacing: 4) {
                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(alarm.isActive ? AppColors.text : AppColors.inactive)
                            .lineLimit(1)
                    }

                    Text(scheduleLine)
                        .font(.caption)
                        .foregroundStyle(detailColor)
                        .lineLimit(1)

                    if alarm.isActive && !nextAlarmText.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(nextAlarmText)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppColors.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: Binding(
                    get: { alarm.isActive },
                    set: { _ in viewModel.toggleAlarm(id: alarm.id) }
                ))
                .tint(AppColors.primary)
                .labelsHidden()
            }
            .padding(20)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: alarm.isActive ? AppColors.cardShadow : .clear, radius: 20, y: 6)
            .opacity(alarm.isActive ? 1 : 0.75)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditAlarm) {
            EditAlarmView(alarm: alarm)
        }
    }
}

#Preview {
    AlarmItemView(alarm: Alarm(
        time: "07:30",
        label: "Morning Wake Up",
        repeatDays: ["mon", "tue", "wed", "thu", "fri"],
        questionCount: 3,
        questionDifficulty: "medium"
    ))
    .environment(AlarmsViewModel())
    .preferredColorScheme(.dark)
    .padding()
    .background(AppColors.background)
}
