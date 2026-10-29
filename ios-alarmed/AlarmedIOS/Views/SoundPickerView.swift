import SwiftUI

/// List of the bundled alarm tones. Tap the speaker to preview, tap the row
/// to choose — a checkmark marks the current selection. Pushed from the
/// Create/Edit alarm form.
struct SoundPickerView: View {
    @Binding var selectedSoundId: String
    @State private var previewer = AlarmSoundTester()
    @State private var previewingSoundId: String? = nil
    @State private var previewStatus: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Tones")
                SectionCard {
                    ForEach(Array(AlarmSound.all.enumerated()), id: \.element.id) { index, tone in
                        if index > 0 { RowDivider(leadingInset: 70) }
                        row(for: tone)
                    }
                }

                Text("Every tone is loudness-processed for the lock-screen alarm. The alarm plays at your \"Ringtone & Alerts\" volume.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.top, Spacing.xxs)
                    .fixedSize(horizontal: false, vertical: true)

                if let previewStatus {
                    Text(previewStatus)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, Spacing.xxs)
                }
            }
            .padding(Spacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { previewer.stop() }
    }

    private func row(for tone: AlarmSound) -> some View {
        let isSelected = tone.id == selectedSoundId
        let isPreviewing = tone.id == previewingSoundId
        return HStack(spacing: Spacing.sm) {
            Button {
                togglePreview(of: tone)
            } label: {
                Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isPreviewing ? AppColors.text : AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(isPreviewing ? AppColors.primary : AppColors.primarySoft, in: Circle())
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressableStyle(scale: 0.9))
            .accessibilityLabel(isPreviewing ? "Stop preview" : "Preview \(tone.name)")

            Button {
                selectedSoundId = tone.id
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tone.name)
                            .font(isSelected ? AppFont.rowTitleEmphasis : AppFont.rowTitle)
                            .foregroundStyle(AppColors.text)
                        if tone.id == AlarmSound.defaultID {
                            Text("Default")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(tone.name)\(isSelected ? ", selected" : "")")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs + 2)
        .sensoryFeedback(.selection, trigger: isSelected)
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
