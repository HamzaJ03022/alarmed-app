import SwiftUI

/// Limited alarm management reachable from the paywall: alarms that are
/// already scheduled keep ringing, so a locked-out user can still turn them
/// off or delete them — but never create, edit or re-enable.
struct ManageAlarmsLockedView: View {
    @Environment(AlarmsViewModel.self) private var viewModel

    private var sortedAlarms: [Alarm] {
        viewModel.alarms.sorted { a, b in
            if a.isActive != b.isActive { return a.isActive }
            return a.time < b.time
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Your alarms keep ringing even without a subscription. Turn any of them off or delete them here — creating new alarms needs Alarmed Pro.")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxs)

                if viewModel.alarms.isEmpty {
                    Text("You have no alarms.")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Spacing.xxl)
                } else {
                    VStack(spacing: 10) {
                        ForEach(sortedAlarms) { alarm in
                            LockedAlarmRow(alarm: alarm)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.background)
        .navigationTitle("Existing alarms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LockedAlarmRow: View {
    let alarm: Alarm

    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showDeleteConfirm = false

    private var time: (main: String, suffix: String) { ClockParts.split(alarm.time) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(time.main)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(alarm.isActive ? AppColors.text : AppColors.inactive)
                Text(time.suffix)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
                Text(alarm.isActive ? "On" : "Off")
                    .font(.caption)
                    .foregroundStyle(AppColors.inactive)
            }

            Spacer(minLength: 0)

            Toggle("Alarm on", isOn: Binding(
                get: { alarm.isActive },
                set: { newValue in
                    // Locked: only turning OFF is allowed. Re-enabling is a
                    // Pro action and is blocked in the view model as well.
                    if !newValue { viewModel.toggleAlarm(id: alarm.id) }
                }
            ))
            .labelsHidden()
            .tint(AppColors.primary)
            .disabled(!alarm.isActive)
            .accessibilityHint(alarm.isActive ? "Turns this alarm off" : "Re-enabling needs Alarmed Pro")

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(AppColors.warning)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceElevated, in: Circle())
            }
            .buttonStyle(PressableStyle(scale: 0.92))
            .accessibilityLabel("Delete alarm")
            .confirmationDialog(
                "Delete this alarm?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteAlarm(id: alarm.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The alarm will stop ringing and be removed from the list.")
            }
        }
        .padding(Spacing.md)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ManageAlarmsLockedView()
    }
    .environment(AlarmsViewModel())
    .preferredColorScheme(.dark)
}
