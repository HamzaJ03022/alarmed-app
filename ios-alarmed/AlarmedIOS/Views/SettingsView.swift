import SwiftUI

struct SettingsView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showClearHistoryAlert = false
    @State private var showClearAlarmsAlert = false
    @State private var showQuotes = false
    @State private var showPrivacyPolicy = false
    @State private var showEngine = false

    private var health: EngineHealth { EngineHealth(viewModel: viewModel) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if case .warning(let message) = health {
                        WarningStrip(message: message) { showEngine = true }
                    }

                    alarmSection
                    loudSection
                    engineSection
                    quotesSection
                    dataSection
                    aboutSection

                    Text("Alarmed \(appVersion)")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.inactive)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xxl + Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showEngine) {
                EngineDiagnosticsView()
            }
            .task { viewModel.refreshEngineDiagnostics() }
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

    // MARK: - Alarm

    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Alarm")
            SectionCard {
                ActionRow(
                    icon: "play.fill",
                    title: viewModel.isPlayingTestSound ? "Stop test sound" : "Play test sound",
                    subtitle: viewModel.testSoundStatus,
                    trailingSystemImage: viewModel.isPlayingTestSound ? "stop.circle.fill" : "play.circle.fill"
                ) {
                    viewModel.playTestSound()
                }
                RowDivider(leadingInset: 58)
                ToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Vibration",
                    isOn: Binding(
                        get: { viewModel.vibrationEnabled },
                        set: { viewModel.vibrationEnabled = $0 }
                    )
                )
                RowDivider(leadingInset: 58)
                InfoRow(
                    icon: "speaker.wave.3.fill",
                    iconTint: AppColors.textSecondary,
                    title: "Alarm volume: always max",
                    subtitle: "Locked at full volume until the challenge is solved"
                )
            }
        }
    }

    // MARK: - Make it loud

    /// The lock-screen alarm plays at the system "Ringtone & Alerts" volume,
    /// which no app can raise — this one-time setup makes it loud and stops
    /// the volume buttons from lowering it overnight.
    private var loudSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Make it loud")
            SectionCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    tipStep(number: 1, text: "In Settings → Sounds & Haptics, drag \"Ringtone & Alerts\" all the way up.")
                    tipStep(number: 2, text: "Turn off \"Change with Buttons\" so the volume buttons can't lower your alarm overnight.")
                    Text("Silencing a ringing alarm with the side or volume buttons only pauses it — it rings again every minute until you solve the challenge.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)

                RowDivider()

                ActionRow(
                    icon: "gearshape.fill",
                    title: "Open Settings",
                    trailingSystemImage: "arrow.up.right",
                    action: openSystemSettings
                )
            }
        }
    }

    private func tipStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 26, height: 26)
                .background(AppColors.primarySoft, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Engine (secondary, never hidden)

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Reliability")
            SectionCard {
                Button {
                    showEngine = true
                } label: {
                    RowContent(
                        icon: "alarm.waves.left.and.right",
                        iconTint: health.color,
                        title: "Alarm Engine",
                        subtitle: health.summary
                    ) {
                        HStack(spacing: Spacing.xs) {
                            StatusPill(text: health.pillText, color: health.color)
                            Chevron()
                        }
                    }
                }
                .buttonStyle(RowButtonStyle())
                .accessibilityLabel("Alarm Engine, \(health.pillText). \(health.summary)")
            }
        }
    }

    // MARK: - Quotes / Data / About

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Quotes")
            SectionCard {
                NavigationRow(
                    icon: "quote.bubble.fill",
                    title: "Motivational Quotes",
                    value: "\(viewModel.quotes.count)"
                ) { showQuotes = true }
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Data")
            SectionCard {
                ActionRow(icon: "clock.arrow.circlepath", title: "Clear Alarm History", role: .destructive) {
                    showClearHistoryAlert = true
                }
                RowDivider(leadingInset: 58)
                ActionRow(icon: "trash", title: "Delete All Alarms", role: .destructive) {
                    showClearAlarmsAlert = true
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "About")
            SectionCard {
                NavigationRow(icon: "questionmark.circle.fill", title: "How to Use", action: showHelp)
                RowDivider(leadingInset: 58)
                NavigationRow(icon: "info.circle.fill", title: "About Alarmed", action: showAbout)
                RowDivider(leadingInset: 58)
                NavigationRow(icon: "lock.shield.fill", title: "Privacy Policy") { showPrivacyPolicy = true }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
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
            message: "Alarmed is an app designed to help you wake up on time by requiring you to answer questions before turning off the alarm. Version \(appVersion)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }

    private func presentAlert(_ alert: UIAlertController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(alert, animated: true)
    }
}

// MARK: - Engine health

/// Summarises the engine diagnostics into one status. Derived purely from
/// the diagnostics the view model already collects — nothing is hidden.
enum EngineHealth: Equatable {
    case healthy
    case idle
    case warning(String)

    init(viewModel: AlarmsViewModel) {
        let permission = (viewModel.rawPermissionState ?? "").lowercased()
        let status = viewModel.alarmScheduleStatus ?? ""
        let lowerStatus = status.lowercased()
        let hasActive = viewModel.alarms.contains(where: \.isActive)

        if permission.contains("denied") || lowerStatus.contains("permission: denied") {
            self = .warning("Alarm permission is off — alarms may not ring. Tap for details.")
        } else if lowerStatus.contains("could not schedule") || lowerStatus.contains("fallback also failed") {
            self = .warning("The last alarm couldn't be scheduled. Tap for details.")
        } else if hasActive && viewModel.alarmsMissingBackups > 0 {
            let n = viewModel.alarmsMissingBackups
            self = .warning("\(n) \(n == 1 ? "alarm is" : "alarms are") missing re-ring backups. Tap for details.")
        } else if lowerStatus.contains("alarmkit unavailable") {
            self = .warning("Using notification fallback instead of system alarms. Tap for details.")
        } else if !hasActive {
            self = .idle
        } else {
            self = .healthy
        }
    }

    var pillText: String {
        switch self {
        case .healthy: "Healthy"
        case .idle: "Idle"
        case .warning: "Check"
        }
    }

    var color: Color {
        switch self {
        case .healthy: AppColors.success
        case .idle: AppColors.textSecondary
        case .warning: AppColors.warning
        }
    }

    var summary: String {
        switch self {
        case .healthy: "All alarms armed with re-ring backups"
        case .idle: "No alarms are on"
        case .warning: "Something needs attention"
        }
    }
}

#Preview {
    SettingsView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
