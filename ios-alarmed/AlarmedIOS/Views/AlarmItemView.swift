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

    var body: some View {
        HStack(spacing: 0) {
            Button {
                showEditAlarm = true
            } label: {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TimeFormatter.formatTime12h(alarm.time))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(alarm.isActive ? AppColors.text : AppColors.inactive)
                        Text(TimeFormatter.formatRepeatDays(alarm.repeatDays))
                            .font(.caption)
                            .foregroundStyle(alarm.isActive ? AppColors.textSecondary : AppColors.inactive)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if !alarm.label.isEmpty {
                            Text(alarm.label)
                                .font(.body.weight(.medium))
                                .foregroundStyle(alarm.isActive ? AppColors.text : AppColors.inactive)
                        }
                        if alarm.isActive && !nextAlarmText.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.primary)
                                Text(nextAlarmText)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        Text("\(alarm.questionCount) \(alarm.questionCount == 1 ? "question" : "questions") \u{2022} \(alarm.questionDifficulty)")
                            .font(.caption)
                            .foregroundStyle(alarm.isActive ? AppColors.textSecondary : AppColors.inactive)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                Button {
                    showEditAlarm = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 44, height: 44)
                }

                Toggle("", isOn: Binding(
                    get: { alarm.isActive },
                    set: { _ in viewModel.toggleAlarm(id: alarm.id) }
                ))
                .tint(AppColors.primary)
                .labelsHidden()
            }
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 6)
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
