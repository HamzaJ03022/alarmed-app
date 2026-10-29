import SwiftUI

struct HistoryListView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showCreateAlarm = false

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
                    ScrollView {
                        EmptyStateView(
                            title: "No history yet",
                            description: "Every alarm you beat shows up here, along with your wake-up streak.",
                            actionText: "Create Alarm",
                            systemImage: "chart.bar.fill"
                        ) {
                            showCreateAlarm = true
                        }
                        .containerRelativeFrame(.vertical, alignment: .center) { length, _ in
                            length * 0.85
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            StreakCardView(streak: streakCount)

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                SectionHeader(title: "Recent wake-ups")
                                SectionCard {
                                    ForEach(Array(sortedHistory.enumerated()), id: \.element.id) { index, item in
                                        if index > 0 { RowDivider() }
                                        HistoryItemView(item: item, alarms: viewModel.alarms)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xxl + Spacing.xl)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateAlarm) {
                CreateAlarmView()
            }
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

    private var alarmName: String {
        guard let alarm else { return "Deleted alarm" }
        return alarm.label.isEmpty ? TimeFormatter.formatTime12h(alarm.time) : alarm.label
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            IconTile(
                systemName: item.dismissed ? "xmark" : "checkmark",
                tint: item.dismissed ? AppColors.error : AppColors.success
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(dateText)
                    .font(AppFont.rowTitleEmphasis)
                    .foregroundStyle(AppColors.text)
                Text("\(alarmName) \u{2022} \(timeText)")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                if !item.dismissed {
                    Text("\(item.questionsCorrect)/\(item.questionsAnswered) questions correct")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.inactive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusPill(
                text: item.dismissed ? "Missed" : "Completed",
                color: item.dismissed ? AppColors.error : AppColors.success
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HistoryListView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
