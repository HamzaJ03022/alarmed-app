import SwiftUI

struct CreateAlarmView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft = AlarmDraft()
    @State private var didApplyDefaults = false
    @State private var showSoundPicker = false

    var body: some View {
        NavigationStack {
            AlarmEditorForm(draft: $draft, showSoundPicker: $showSoundPicker)
                .navigationDestination(isPresented: $showSoundPicker) {
                    SoundPickerView(selectedSoundId: $draft.sound)
                }
                .onAppear(perform: applyOnboardingDefaults)
                .navigationTitle("New Alarm")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppColors.background, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    SaveBar(
                        title: "Save Alarm",
                        isEnabled: draft.phraseIsValid,
                        disabledHint: "Your phrase needs at least \(AlarmDraft.phraseMinLength) characters",
                        action: saveAlarm
                    )
                }
        }
        .presentationBackground(AppColors.background)
    }

    private func applyOnboardingDefaults() {
        guard !didApplyDefaults else { return }
        didApplyDefaults = true
        draft.dismissalMode = viewModel.defaultChallengeMode
        draft.dismissPhrase = viewModel.onboardingPhrase
    }

    private func saveAlarm() {
        let time = draft.time
        let alarm = Alarm(
            time: time,
            label: draft.trimmedLabel,
            repeatDays: draft.repeatDays,
            questionCount: draft.questionCount,
            questionDifficulty: draft.difficulty,
            questionCategories: draft.categories,
            vibrate: draft.vibrate,
            dismissalMode: draft.dismissalMode,
            dismissPhrase: draft.savedPhrase,
            sound: draft.sound
        )
        viewModel.addAlarm(alarm)
        viewModel.saveConfirmationMessage =
            "Alarm saved \u{2022} rings at \(TimeFormatter.formatTime12h(time))"
        HapticManager.successNotification()
        dismiss()
    }
}

#Preview {
    CreateAlarmView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
