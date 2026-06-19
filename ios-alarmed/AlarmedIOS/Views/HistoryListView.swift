import SwiftUI

struct HistoryListView: View {
    @Environment(AlarmsViewModel.self) private var viewModel

    private var sortedHistory: [AlarmHistory] {
        viewModel.history.sorted {
            $0.date > $1.date
        }
    }

    private var streakCount: Int {
        viewModel.getStreakCount()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.history.isEmpty {
                    EmptyStateView(
                        title: "No History Yet",
                        description: "Your alarm history will appear here once you've used your alarms.",
                        actionText: "Create Alarm",
                        systemImage: "chart.bar.fill"
                    ) {}
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            StreakCardView(streak: streakCount)

                            ForEach(sortedHistory) { item in
                                HistoryItemView(item: item, alarms: viewModel.alarms)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct HistoryItemView: View {
    let item: AlarmHistory
    let alarms: [Alarm]

    private var alarm: Alarm? { alarms.first { $0.id == item.alarmId } }

    private var dateText: String {
        ISO8601DateFormatter().date(from: item.date)?
            .formatted(Date.FormatStyle()
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day(.defaultDigits)) ?? ""
    }

    private var timeText: String {
        ISO8601DateFormatter().date(from: item.wakeUpTime)?
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateText)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                Spacer()
                statusBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("\(alarm?.label ?? "Deleted Alarm") \u{2022} \(timeText)")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if !item.dismissed {
                    HStack(spacing: 4) {
                        Text("\(item.questionsCorrect)/\(item.questionsAnswered) questions correct")
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary)
                        if item.snoozeCount > 0 {
                            Text("\u{2022} \(item.snoozeCount) \(item.snoozeCount == 1 ? "snooze" : "snoozes")")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 6)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.dismissed ? "xmark.circle.fill" : "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(item.dismissed ? AppColors.error : AppColors.success)
            Text(item.dismissed ? "Missed" : "Completed")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(item.dismissed ? AppColors.error : AppColors.success)
        }
    }
}

#Preview {
    HistoryListView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
