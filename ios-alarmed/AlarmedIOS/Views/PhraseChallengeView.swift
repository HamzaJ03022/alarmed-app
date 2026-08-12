import SwiftUI

struct PhraseChallengeView: View {
    let phrase: String
    let onCorrect: () -> Void
    let onSnooze: () -> Void
    let snoozeCount: Int

    @State private var input: String = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            promptSection
            inputSection
            snoozeButton
        }
        .onAppear { isFocused = true }
    }

    private var promptSection: some View {
        VStack(spacing: 8) {
            Text("Type your phrase to dismiss")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            TextEditor(text: $input)
                .font(.body)
                .foregroundStyle(AppColors.text)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    hasSubmitted && !isCorrect
                        ? AppColors.error.opacity(0.1)
                        : AppColors.inputBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            hasSubmitted && !isCorrect ? AppColors.error : AppColors.inputBorder,
                            lineWidth: 1
                        )
                )
                .overlay(alignment: .topLeading) {
                    if input.isEmpty {
                        Text("Type your phrase here...")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                .focused($isFocused)
                .onChange(of: input) { _, _ in
                    if hasSubmitted {
                        hasSubmitted = false
                        isCorrect = false
                    }
                }

            if hasSubmitted && !isCorrect {
                VStack(spacing: 12) {
                    Text("Incorrect — try again")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.error)

                    Button(action: resetInput) {
                        Text("Try Again")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.inputBorder, lineWidth: 1))
                    }
                }
                .frame(maxWidth: .infinity)
            } else if !hasSubmitted {
                Button(action: handleSubmit) {
                    Text("Submit")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            input.isEmpty ? AppColors.primary.opacity(0.5) : AppColors.primary,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
                }
                .disabled(input.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxHeight: .infinity)
    }

    private var snoozeButton: some View {
        Button(action: resetInput) {
            Text("Start Over (\(snoozeCount))")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.error, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppColors.error.opacity(0.3), radius: 12, y: 6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func handleSubmit() {
        guard !input.isEmpty else { return }
        let correct = input == phrase
        isCorrect = correct
        hasSubmitted = true
        if correct {
            onCorrect()
        }
    }

    private func resetInput() {
        input = ""
        hasSubmitted = false
        isCorrect = false
        isFocused = true
        onSnooze()
    }
}

#Preview {
    PhraseChallengeView(
        phrase: "I want to wake up",
        onCorrect: {},
        onSnooze: {},
        snoozeCount: 0
    )
    .preferredColorScheme(.dark)
}
