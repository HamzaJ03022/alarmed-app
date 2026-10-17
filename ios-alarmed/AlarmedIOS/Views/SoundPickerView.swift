import SwiftUI

/// Full-screen list of the bundled alarm tones. Tap the speaker to preview,
/// tap the row to choose — a checkmark marks the current selection.
struct SoundPickerView: View {
    @Binding var selectedSoundId: String
    @Environment(\.dismiss) private var dismiss
    @State private var previewer = AlarmSoundTester()
    @State private var previewingSoundId: String? = nil
    @State private var previewStatus: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AlarmSound.all) { tone in
                        row(for: tone)
                    }

                    Text("Every tone is loudness-processed for the lock-screen alarm. The alarm plays at your \"Ringtone & Alerts\" volume.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)

                    if let previewStatus {
                        Text(previewStatus)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Alarm Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { previewer.stop(); dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
            .onDisappear { previewer.stop() }
        }
    }

    private func row(for tone: AlarmSound) -> some View {
        let isSelected = tone.id == selectedSoundId
        let isPreviewing = tone.id == previewingSoundId
        return HStack(spacing: 14) {
            Button {
                togglePreview(of: tone)
            } label: {
                Image(systemName: isPreviewing ? "stop.circle.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.inputBackground, in: Circle())
            }
            .accessibilityLabel(isPreviewing ? "Stop preview" : "Preview \(tone.name)")

            Button {
                selectedSoundId = tone.id
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tone.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    if tone.id == AlarmSound.defaultID {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .accessibilityLabel("Selected")
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Alarm sound \(tone.name)\(isSelected ? ", selected" : "")")
    }

    private func togglePreview(of tone: AlarmSound) {
        if tone.id == previewingSoundId {
            previewer.stop()
            previewingSoundId = nil
            previewStatus = nil
        } else {
            previewStatus = previewer.playPreview(of: tone)
            previewingSoundId = tone.id
        }
    }
}
