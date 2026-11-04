import SwiftUI

/// The calm "Are you awake?" screen, opened by tapping the check-in
/// notification's body or by a follow-up ring routed in-app. Opening this
/// screen never confirms — only the big button does.
struct AreYouAwakeView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var isConfirming = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                header
                message
                Spacer()
                awakeButton
            }
            .padding(24)
        }
        .onAppear { startRinging() }
        .onDisappear { AudioManager.shared.stop() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.primary)
                .frame(width: 84, height: 84)
                .background(AppColors.primary.opacity(0.14), in: Circle())

            Text("Are you awake?")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.text)

            Text(TimeFormatter.formatTime12h(alarm.time))
                .font(.title3.weight(.medium).monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
        }
        .multilineTextAlignment(.center)
    }

    private var message: some View {
        Text("Just checking you're up and ready to start your day. Confirm below, or the follow-up alarm will ring.")
            .font(.body)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
    }

    private var awakeButton: some View {
        Button {
            guard !isConfirming else { return }
            isConfirming = true
            HapticManager.successNotification()
            viewModel.confirmCheckIn()
        } label: {
            Label("I'm awake", systemImage: "sun.max.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isConfirming)
        .accessibilityHint("Stops the check-in and cancels the follow-up alarm")
    }

    /// The follow-up ring plays here too, until it's confirmed.
    private func startRinging() {
        AudioManager.shared.playAlarm(soundId: alarm.sound, vibrate: alarm.vibrate)
    }
}

#Preview {
    AreYouAwakeView(alarm: Alarm(time: "07:30", label: "Morning"))
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
