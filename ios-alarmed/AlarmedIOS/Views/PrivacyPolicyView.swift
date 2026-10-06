import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy Policy")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Text("Last updated: August 12, 2026")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.bottom, 16)

                section("Overview",
                        "Alarmed is an alarm clock application that helps you wake up by requiring you to answer questions or type a phrase to dismiss alarms. We respect your privacy and are committed to protecting it.")

                section("Data We Collect",
                        "Alarmed does not collect, store, or transmit any personal data. All app data — including alarms, settings, history, and quotes — is stored locally on your device. No data is ever sent to any server.")

                section("Permissions",
                        "Alarmed requests the following permissions to provide its core functionality:")
                bullet("Notifications: To schedule and deliver alarm notifications at your specified times.")
                bullet("Audio: To play alarm sounds when an alarm is triggered.")
                bullet("Vibration: To vibrate your device when an alarm rings.")

                section("Third-Party Services",
                        "Alarmed does not use any third-party analytics, advertising, or tracking services. The app does not contain any SDKs that collect or transmit user data.")

                section("Children's Privacy",
                        "Alarmed is suitable for users of all ages and does not collect any personal information from anyone, including children.")

                section("Changes to This Policy",
                        "We may update this privacy policy from time to time. Any changes will be posted within the app and on this page.")

                section("Contact Us",
                        "If you have any questions about this privacy policy, please contact us at support@nyytech.com.")
            }
            .padding(24)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.text)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)
        }
        .padding(.bottom, 8)
    }

    private func bullet(_ text: String) -> some View {
        Text("• \(text)")
            .font(.subheadline)
            .foregroundStyle(AppColors.textSecondary)
            .lineSpacing(3)
            .padding(.leading, 8)
            .padding(.bottom, 2)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
    .preferredColorScheme(.dark)
}
