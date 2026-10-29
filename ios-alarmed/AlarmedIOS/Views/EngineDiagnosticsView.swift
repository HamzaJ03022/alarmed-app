import SwiftUI

/// Full alarm-engine diagnostics: scheduling outcome, build facts, raw
/// permission state, registered system alarms, re-ring backups and the
/// on-demand AlarmKit check. Pushed from Settings.
struct EngineDiagnosticsView: View {
    @Environment(AlarmsViewModel.self) private var viewModel

    private var health: EngineHealth { EngineHealth(viewModel: viewModel) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                statusHeader

                if let status = viewModel.alarmScheduleStatus {
                    group("Last scheduling result") {
                        diagnosticText(status)
                    }
                }

                if !viewModel.backupDiagnostics.isEmpty || viewModel.systemAlarmCount != nil {
                    group("Re-ring backups") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(viewModel.backupDiagnostics, id: \.self) { line in
                                HStack(alignment: .top, spacing: Spacing.xs) {
                                    Image(systemName: line.contains("\(AlarmBackupIds.count) of \(AlarmBackupIds.count)")
                                          ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .font(.footnote)
                                        .foregroundStyle(line.contains("\(AlarmBackupIds.count) of \(AlarmBackupIds.count)")
                                                         ? AppColors.success : AppColors.warning)
                                    diagnosticText(line)
                                }
                            }
                            if let count = viewModel.systemAlarmCount {
                                diagnosticText("Registered system alarms: \(count) (each alarm + its re-ring backups)")
                            }
                        }
                    }
                }

                if !viewModel.alarmGroundTruth.isEmpty {
                    group("Build & permission") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.alarmGroundTruth, id: \.self) { line in
                                diagnosticText(line)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeader(title: "AlarmKit check")
                    Button {
                        viewModel.runAlarmKitCheck()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            if viewModel.isRunningCheck {
                                ProgressView().tint(AppColors.primary)
                                Text("Running check…")
                            } else {
                                Image(systemName: "waveform.path.ecg")
                                Text("Run AlarmKit check")
                            }
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isRunningCheck)

                    if let check = viewModel.alarmCheckResult {
                        SectionCard {
                            diagnosticText(check).padding(Spacing.md)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.xxl + Spacing.xl)
        }
        .background(AppColors.background)
        .navigationTitle("Alarm Engine")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.refreshEngineDiagnostics() }
        .refreshable { viewModel.refreshEngineDiagnostics() }
    }

    private var statusHeader: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: {
                switch health {
                case .healthy: "checkmark.shield.fill"
                case .idle: "moon.zzz.fill"
                case .warning: "exclamationmark.triangle.fill"
                }
            }())
            .font(.title2)
            .foregroundStyle(health.color)
            .frame(width: 52, height: 52)
            .background(health.color.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                StatusPill(text: health.pillText, color: health.color)
                Text({
                    if case .warning(let message) = health { return message }
                    return health.summary
                }())
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: title)
            SectionCard {
                content().padding(Spacing.md)
            }
        }
    }

    private func diagnosticText(_ text: String) -> some View {
        Text(text)
            .font(.footnote.monospacedDigit())
            .foregroundStyle(AppColors.textSecondary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
