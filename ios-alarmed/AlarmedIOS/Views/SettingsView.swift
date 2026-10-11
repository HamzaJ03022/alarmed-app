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
                VStack(spacing: 20) {
                    warningCard
                    loudnessTipCard

                    alarmEngineCard
                    alarmSettingsCard
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

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.warning)
            VStack(alignment: .leading, spacing: 6) {
                Text("Important")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppColors.warning)
                Text("Alarms ring even when the app is closed. Keep notifications enabled — on iOS 18–25 alarms are delivered as notifications.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.warning.opacity(0.9))
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .background(AppColors.warningBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.warning, lineWidth: 1))
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
                    if let raw = viewModel.rawPermissionState {
                        Text(raw)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            if let count = viewModel.systemAlarmCount {
                Text("Registered system alarms: \(count) (each alarm + its re-ring backups)")
                    .font(.caption.weight(.semibold))
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

    private var alarmSettingsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Alarm Settings")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.text)

            HStack(spacing: 14) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 20)
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
            .padding(.vertical, 6)

            Button(action: { viewModel.playTestSound() }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isPlayingTestSound ? "stop.fill" : "play.fill")
                    Text(viewModel.isPlayingTestSound ? "Stop test sound" : "Play test sound")
                    Spacer()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if let status = viewModel.testSoundStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            settingToggle(
                icon: "waveform.path",
                title: "Vibration",
                isOn: Binding(
                    get: { viewModel.vibrationEnabled },
                    set: { viewModel.vibrationEnabled = $0 }
                )
            )

            navigationButton(
                icon: "quote.bubble.fill",
                title: "Motivational Quotes",
                subtitle: "\(viewModel.quotes.count) quotes",
                action: { showQuotes = true }
            )
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Data Management")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.text)

            Button(action: { showClearHistoryAlert = true }) {
                HStack(spacing: 14) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(AppColors.error)
                    Text("Clear Alarm History")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.error)
                    Spacer()
                }
                .padding(.vertical, 18)
            }

            Button(action: { showClearAlarmsAlert = true }) {
                HStack(spacing: 14) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(AppColors.error)
                    Text("Delete All Alarms")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.error)
                    Spacer()
                }
                .padding(.vertical, 18)
            }
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("About")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.text)

            Button(action: showHelp) {
                HStack(spacing: 14) {
                    Image(systemName: "questionmark.circle")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("How to Use")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                }
                .padding(.vertical, 18)
            }

            Button(action: showAbout) {
                HStack(spacing: 14) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("About Alarmed")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                }
                .padding(.vertical, 18)
            }

            navigationButton(
                icon: "lock.shield",
                title: "Privacy Policy",
                subtitle: "How Alarmed handles your data",
                action: { showPrivacyPolicy = true }
            )
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 8)
    }

    private func settingToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 20)
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.text)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppColors.primary)
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }

    private func navigationButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, 6)
        }
    }

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
