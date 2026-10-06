import SwiftUI

struct OnboardingView: View {
    @Environment(AlarmsViewModel.self) private var viewModel

    @State private var page = 0
    @State private var showSetup = false
    @State private var mode = "questions"
    @State private var phrase = ""
    @State private var permissionDenied = false
    @State private var isRequesting = false

    private let slides: [(icon: String, title: String, body: String)] = [
        (
            "alarm.fill",
            "Earn your wake-up",
            "Your alarm keeps ringing until you finish the challenge you set. There is no snooze escape hatch."
        ),
        (
            "character.textbox",
            "Choose your challenge",
            "Answer a preset number of questions with a 90-second timer each — or type your saved phrase exactly to dismiss."
        ),
        (
            "bell.badge.fill",
            "Alarms that break through",
            "Time-sensitive notifications ring even when the app is closed. Notifications are what make background alarms fire."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Alarmed")
                    .font(.headline)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Button {
                    viewModel.completeOnboarding(mode: "questions", phrase: "")
                } label: {
                    Text("Skip")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .disabled(isRequesting)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if showSetup {
                setupView
            } else {
                cardsView
            }
        }
        .background(AppColors.background)
    }

    // MARK: - Intro cards

    private var cardsView: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    VStack(spacing: 16) {
                        Image(systemName: slide.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 110, height: 110)
                            .background(AppColors.primary.opacity(0.15), in: Circle())
                            .padding(.bottom, 16)

                        Text(slide.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.center)

                        Text(slide.body)
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        if index == slides.count - 1 {
                            Text("You can enable notifications on the next step.")
                                .font(.footnote)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 32)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? AppColors.primary : AppColors.inactive)
                        .frame(width: index == page ? 20 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: page)
                }
            }
            .padding(.bottom, 24)

            Button {
                if page < slides.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    withAnimation { showSetup = true }
                }
            } label: {
                Text(page < slides.count - 1 ? "Continue" : "Make it yours")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Make it yours

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Make it yours")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.text)

                Text("Pick how you want to dismiss your alarms by default. You can change it on every alarm.")
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)

                modeOption(
                    icon: "alarm.fill",
                    title: "Questions",
                    body: "Answer a preset number of questions correctly before the alarm stops.",
                    value: "questions"
                )

                modeOption(
                    icon: "character.textbox",
                    title: "Type a Phrase",
                    body: "Write your own motivation — you'll have to type it exactly to dismiss.",
                    value: "phrase"
                )

                if mode == "phrase" {
                    phraseSection
                }

                if permissionDenied {
                    Text("No worries — alarms still ring while the app is open. You can enable notifications anytime in your device settings.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.warning)
                        .lineSpacing(3)
                }

                enableButton
            }
            .padding(20)
        }
    }

    private func modeOption(icon: String, title: String, body: String, value: String) -> some View {
        Button {
            mode = value
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(mode == value ? AppColors.text : AppColors.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.inputBackground, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.text)
                    Text(body)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(2)
                }
                Spacer()
            }
            .padding(20)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(mode == value ? AppColors.primary : .clear, lineWidth: 2)
            )
        }
    }

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $phrase)
                .font(.body)
                .foregroundStyle(AppColors.text)
                .frame(minHeight: 90)
                .padding(12)
                .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if phrase.isEmpty {
                        Text("e.g. I want to wake up so I can get to work on time and not be late")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: phrase) { _, newValue in
                    if newValue.count > 100 {
                        phrase = String(newValue.prefix(100))
                    }
                }

            Text("\(phrase.count)/100")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if !phrase.isEmpty && phrase.count < 10 {
                Text("Phrase must be at least 10 characters")
                    .font(.caption)
                    .foregroundStyle(AppColors.error)
            }

            Text("You'll need to type this exactly (case-sensitive) to dismiss the alarm.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(2)
        }
        .padding(20)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Enable Alarms

    private var phraseIsValid: Bool {
        mode == "questions" || phrase.count >= 10
    }

    private var enableButton: some View {
        Button {
            handleEnableAlarms()
        } label: {
            Text(enableLabel)
                .font(.body.weight(.bold))
                .foregroundStyle(AppColors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    phraseIsValid ? AppColors.primary : AppColors.primary.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .disabled(!phraseIsValid || isRequesting)
    }

    private var enableLabel: String {
        permissionDenied ? "Get Started" : "Enable Alarms"
    }

    private func handleEnableAlarms() {
        if permissionDenied {
            viewModel.completeOnboarding(mode: mode, phrase: phrase)
            return
        }
        isRequesting = true
        NotificationManager.shared.requestPermission { granted in
            isRequesting = false
            if granted {
                viewModel.completeOnboarding(mode: mode, phrase: phrase)
            } else {
                permissionDenied = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AlarmsViewModel())
}
