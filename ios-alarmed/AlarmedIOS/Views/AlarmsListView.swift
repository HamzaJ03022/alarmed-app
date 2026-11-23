import SwiftUI

struct AlarmsListView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showCreateAlarm = false
    /// Alarm waiting on the "Delete alarm?" confirmation after a swipe.
    @State private var pendingDelete: Alarm?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.alarms.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            title: "Wake up with purpose",
                            description: "Alarmed keeps ringing until you prove you're awake — by answering questions or typing your own phrase.",
                            actionText: "Create your first alarm",
                            systemImage: "alarm.fill"
                        ) {
                            showCreateAlarm = true
                        }
                        .containerRelativeFrame(.vertical, alignment: .center) { length, _ in
                            length * 0.85
                        }
                    }
                } else {
                    // Re-evaluated every 30s so the hero countdown and the
                    // "next alarm" choice stay live.
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        alarmList(now: context.date)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let message = viewModel.saveConfirmationMessage {
                    ToastView(message: message)
                        .id(message)
                        .padding(.bottom, Spacing.sm)
                        .task {
                            try? await Task.sleep(for: .seconds(2.5))
                            if viewModel.saveConfirmationMessage == message {
                                viewModel.saveConfirmationMessage = nil
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.saveConfirmationMessage)
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.alarms.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            HapticManager.lightImpact()
                            showCreateAlarm = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(AppColors.primary)
                        .accessibilityLabel("Add alarm")
                    }
                }
            }
            .sheet(isPresented: $showCreateAlarm) {
                CreateAlarmView()
            }
            .confirmationDialog(
                "Delete alarm?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { alarm in
                Button("Delete", role: .destructive) {
                    HapticManager.mediumImpact()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        viewModel.deleteAlarm(id: alarm.id)
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { alarm in
                Text("The \(TimeFormatter.formatTime12h(alarm.time)) alarm will stop ringing and be removed.")
            }
        }
    }

    // MARK: - List

    private func alarmList(now: Date) -> some View {
        let next = nextAlarm(now: now)
        let others = sortedAlarms.filter { $0.id != next?.alarm.id }

        // A plain List (styled to look like the cards) so rows get native
        // swipe actions. Only the rows below the hero are swipeable.
        return List {
            Group {
                if let next {
                    NextAlarmHero(alarm: next.alarm, fireDate: next.date, now: now)
                } else {
                    NoAlarmsOnHero()
                }
            }
            .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.lg, trailing: Spacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if !others.isEmpty {
                SectionHeader(title: next == nil ? "Your alarms" : "Other alarms")
                    .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xxs, trailing: Spacing.md))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(others) { alarm in
                    AlarmItemView(alarm: alarm)
                        .listRowInsets(EdgeInsets(top: 5, leading: Spacing.md, bottom: 5, trailing: Spacing.md))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // No destructive role: the row must stay put until
                            // the confirmation is answered.
                            Button {
                                HapticManager.lightImpact()
                                pendingDelete = alarm
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            .tint(AppColors.error)
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, Spacing.xxl + Spacing.xxl, for: .scrollContent)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.alarms)
    }

    /// Alarms ordered by clock time, enabled first.
    private var sortedAlarms: [Alarm] {
        viewModel.alarms.sorted { a, b in
            if a.isActive != b.isActive { return a.isActive }
            return a.time < b.time
        }
    }

    /// The soonest enabled alarm and when it will ring.
    private func nextAlarm(now: Date) -> (alarm: Alarm, date: Date)? {
        viewModel.alarms
            .filter(\.isActive)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let date = TimeFormatter.getNextAlarmTime(time: alarm.time, repeatDays: alarm.repeatDays) else {
                    return nil
                }
                return (alarm, date)
            }
            .min { $0.1 < $1.1 }
            .map { (alarm: $0.0, date: $0.1) }
    }
}

// MARK: - Hero

/// The soonest enabled alarm, shown big with a live countdown.
private struct NextAlarmHero: View {
    let alarm: Alarm
    let fireDate: Date
    let now: Date

    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showEdit = false
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 76

    private var time: (main: String, suffix: String) { ClockParts.split(alarm.time) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Next alarm", systemImage: "alarm.fill")
                    .font(AppFont.sectionLabel)
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .foregroundStyle(AppColors.primary)
                Spacer()
                Toggle("Next alarm", isOn: Binding(
                    get: { alarm.isActive },
                    set: { _ in viewModel.toggleAlarm(id: alarm.id) }
                ))
                .labelsHidden()
                .tint(AppColors.primary)
                .sensoryFeedback(.impact(weight: .light), trigger: alarm.isActive)
            }

            Button {
                showEdit = true
            } label: {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(time.main)
                            .font(.system(size: heroSize, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.text)
                        Text(time.suffix)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "hourglass")
                            .font(.subheadline.weight(.semibold))
                        Text("Rings in \(ClockParts.countdown(to: fireDate, from: now))")
                            .font(.headline)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("· \(ClockParts.dayDescription(for: fireDate, now: now))")
                            .font(.headline.weight(.regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Rectangle().fill(AppColors.divider).frame(height: 1)
                        .padding(.vertical, Spacing.xxs)

                    VStack(alignment: .leading, spacing: 6) {
                        if !alarm.label.isEmpty {
                            Text(alarm.label)
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppColors.text)
                                .lineLimit(2)
                        }
                        AlarmMetaLine(alarm: alarm, isOn: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.985))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Next alarm, \(AlarmAccessibility.label(for: alarm)). Rings in \(ClockParts.spokenCountdown(to: fireDate, from: now))"
            )
            .accessibilityHint("Opens alarm settings")
        }
        .padding(Spacing.lg)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card + 4, style: .continuous))
        .overlay(alignment: .top) {
            // Thin accent edge marks the hero as "the one that matters".
            Capsule()
                .fill(AppColors.primary)
                .frame(width: 44, height: 3)
                .padding(.top, 1)
        }
        .sheet(isPresented: $showEdit) {
            EditAlarmView(alarm: alarm)
        }
    }
}

/// Shown when alarms exist but none are enabled.
private struct NoAlarmsOnHero: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 52, height: 52)
                .background(AppColors.surfaceElevated, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("No alarms on")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                Text("Switch one on below, or add a new alarm.")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card + 4, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AlarmsListView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
