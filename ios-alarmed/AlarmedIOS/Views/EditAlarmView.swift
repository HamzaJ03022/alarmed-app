import SwiftUI

struct EditAlarmView: View {
    let alarm: Alarm
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: AlarmDraft
    @State private var showDeleteConfirm = false
    @State private var showSoundPicker = false

    init(alarm: Alarm) {
        self.alarm = alarm
        _draft = State(initialValue: AlarmDraft(alarm: alarm))
    }

    var body: some View {
        NavigationStack {
            AlarmEditorForm(
                draft: $draft,
                showSoundPicker: $showSoundPicker,
                onDelete: { showDeleteConfirm = true }
            )
            .navigationDestination(isPresented: $showSoundPicker) {
                SoundPickerView(selectedSoundId: $draft.sound)
            }
            .navigationTitle("Edit Alarm")
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
                    action: saveChanges
                )
            }
            .alert("Delete Alarm", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteAlarm(id: alarm.id)
                    viewModel.saveConfirmationMessage = "Alarm deleted"
                    HapticManager.mediumImpact()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this alarm?")
            }
        }
        .presentationBackground(AppColors.background)
    }

    private func saveChanges() {
        let time = draft.time
        viewModel.updateAlarm(id: alarm.id, with: PartialAlarmUpdate(
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
        ))
        viewModel.saveConfirmationMessage =
            "Alarm updated \u{2022} rings at \(TimeFormatter.formatTime12h(time))"
        HapticManager.successNotification()
        dismiss()
    }
}

#Preview {
    EditAlarmView(alarm: Alarm(time: "07:30", label: "Morning", repeatDays: ["mon", "tue", "wed", "thu", "fri"]))
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
