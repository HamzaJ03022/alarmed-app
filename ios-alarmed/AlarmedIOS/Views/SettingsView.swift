import SwiftUI

struct SettingsView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true
    @State private var showClearHistoryAlert = false
    @State private var showClearAlarmsAlert = false
    @State private var showQuotes = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    warningCard

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
                Text("Keep the app running in the background for alarms to work. Closing the app will prevent alarms from ringing.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.warning.opacity(0.9))
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .background(AppColors.warningBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.warning, lineWidth: 1))
    }

    private var alarmSettingsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Alarm Settings")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.text)

            settingToggle(
                icon: "speaker.wave.2.fill",
                title: "Sound",
                isOn: $soundEnabled
            )

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "speaker.slash.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.body)
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                    Text("\(Int(viewModel.volume * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 8)

                Slider(value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.volume = $0 }
                ), in: 0.3...1.0, step: 0.1)
                .tint(AppColors.primary)
            }

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crescendo Alarm")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.text)
                        Text("Gradually increase volume over time")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.crescendoEnabled },
                        set: { viewModel.crescendoEnabled = $0 }
                    ))
                    .tint(AppColors.primary)
                    .labelsHidden()
                }
            }

            settingToggle(
                icon: "waveform.path",
                title: "Vibration",
                isOn: $vibrationEnabled
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
