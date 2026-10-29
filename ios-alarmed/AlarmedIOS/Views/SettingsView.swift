import SwiftUI

struct SettingsView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showClearHistoryAlert = false
    @State private var showClearAlarmsAlert = false
    @State private var showQuotes = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    loudnessTipCard

                    alarmEngineCard
                    alarmsSoundCard
                    quotesCard
                    dataManagementCard
                    aboutCard
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { viewModel.clearHistory() }
            } message: {
                Text("Are you sure you want to clear all alarm history? This cannot be undone.")
            }
            .alert("Clear All Alarms", isPresented: $showClearAlarmsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { viewModel.clearAlarms() }
            } message: {
                Text("Are you sure you want to delete all alarms? This cannot be undone.")
            }
            .sheet(isPresented: $showQuotes) {
                QuotesView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                NavigationStack {
                    PrivacyPolicyView()
                }
            }
        }
    }

    /// The lock-screen alarm plays at the system "Ringtone & Alerts" volume,
    /// which no app can raise — this one-time setup makes it loud and stops
    /// the volume buttons from lowering it overnight.
    private var loudnessTipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                Text("Make your alarm loud")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppColors.text)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                tipStep(number: 1, text: "Open Settings → Sounds & Haptics and drag \"Ringtone & Alerts\" all the way up.")
                tipStep(number: 2, text: "Turn off \"Change with Buttons\" so the volume buttons can't lower your alarm overnight.")
            }

            Text("Silencing a ringing alarm with the side or volume buttons only pauses it — it rings again every minute until you solve the challenge.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(2)

            Button(action: openSystemSettings) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Open Settings")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.primary.opacity(0.35), lineWidth: 1))
    }

    private func tipStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.heavy))
                .foregroundStyle(AppColors.background)
                .frame(width: 22, height: 22)
                .background(AppColors.primary, in: Circle())
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.text)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Live scheduling diagnostics — surfaces AlarmKit registration results
    /// that used to fail silently.
    private var alarmEngineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "alarm.waves.left.and.right")
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                Text("Alarm Engine")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppColors.text)
                Spacer()
            }

            if let status = viewModel.alarmScheduleStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            if !viewModel.alarmGroundTruth.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(viewModel.alarmGroundTruth, id: \.self) { line in
                        Text(line)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            // Per-alarm re-ring health: a muted alarm must re-ring within a
            // minute, so any missing backup count is worth surfacing.
            if !viewModel.backupDiagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(viewModel.backupDiagnostics, id: \.self) { line in
                        Text(line)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            if let count = viewModel.systemAlarmCount {
                Text("Registered system alarms: \(count) (each alarm + its re-ring backups)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button(action: { viewModel.runAlarmKitCheck() }) {
                HStack(spacing: 8) {
                    if viewModel.isRunningCheck {
                        ProgressView()
                            .tint(AppColors.primary)
                        Text("Running check...")
                    } else {
                        Image(systemName: "waveform.path.ecg")
                        Text("Run AlarmKit check")
                    }
                    Spacer()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRunningCheck)

            if let check = viewModel.alarmCheckResult {
                Text(check)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
        .task { viewModel.refreshEngineDiagnostics() }
    }

    // MARK: - Alarms & Sound

    private var alarmsSoundCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardTitle("Alarms & Sound")

            // Static information row (no chevron): explains the locked volume
            HStack(spacing: 14) {
                rowIcon("speaker.wave.3.fill")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alarm volume: always max")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text("Locked at full volume until the challenge is solved")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(.vertical, 12)

            rowDivider

            // Tappable row: plays (or stops) the bundled test tone
            Button(action: { viewModel.playTestSound() }) {
                HStack(spacing: 14) {
                    rowIcon("play.fill")
                    Text("Play test sound")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let status = viewModel.testSoundStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
                    .padding(.bottom, 8)
            }

            rowDivider

            // Static row with a control: the toggle is the affordance
            HStack(spacing: 14) {
                rowIcon("waveform.path")
                Text("Vibration")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.vibrationEnabled },
                    set: { viewModel.vibrationEnabled = $0 }
                ))
                .tint(AppColors.primary)
                .labelsHidden()
            }
            .padding(.vertical, 12)
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var quotesCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardTitle("Quotes")

            navigationRow(
                icon: "quote.bubble.fill",
                title: "Motivational Quotes",
                subtitle: "\(viewModel.quotes.count) quotes",
                action: { showQuotes = true }
            )
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    // MARK: - Data & About

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardTitle("Data Management")

            destructiveRow(title: "Clear Alarm History", action: { showClearHistoryAlert = true })

            rowDivider

            destructiveRow(title: "Delete All Alarms", action: { showClearAlarmsAlert = true })
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardTitle("About")

            navigationRow(icon: "questionmark.circle", title: "How to Use", subtitle: "", action: showHelp)

            rowDivider

            navigationRow(icon: "info.circle", title: "About Alarmed", subtitle: "", action: showAbout)

            rowDivider

            navigationRow(
                icon: "lock.shield",
                title: "Privacy Policy",
                subtitle: "How Alarmed handles your data",
                action: { showPrivacyPolicy = true }
            )
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    // MARK: - Row building blocks

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(AppColors.text)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
    }

    /// Icon inside a tinted circle — marks every interactive row the same way
    private func rowIcon(_ systemName: String, tint: Color = AppColors.primary) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: Circle())
    }

    private func navigationRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                rowIcon(icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func destructiveRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                rowIcon("trash", tint: AppColors.error)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.error)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.error.opacity(0.6))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alerts

    private func showHelp() {
        let alert = UIAlertController(
            title: "How to Use Alarmed",
            message: "1. Create alarms with custom settings\n2. When an alarm rings, you must answer questions to turn it off\n3. Track your wake-up streak in the History tab\n4. Add your own motivational quotes to see when you wake up",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }

    private func showAbout() {
        let alert = UIAlertController(
            title: "About Alarmed",
            message: "Alarmed is an app designed to help you wake up on time by requiring you to answer questions before turning off the alarm. Version 1.0.0",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }

    private func presentAlert(_ alert: UIAlertController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        root.present(alert, animated: true)
    }
}

#Preview {
    SettingsView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
