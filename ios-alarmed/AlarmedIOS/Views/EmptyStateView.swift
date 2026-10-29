import SwiftUI

/// Shared empty state: glowing icon, title, one sentence, one action.
struct EmptyStateView: View {
    let title: String
    let description: String
    let actionText: String
    let systemImage: String
    let onAction: () -> Void

    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.22))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .scaleEffect(breathe ? 1.08 : 0.92)
                Circle()
                    .strokeBorder(AppColors.primary.opacity(0.25), lineWidth: 1)
                    .frame(width: 128, height: 128)
                Circle()
                    .fill(AppColors.card)
                    .frame(width: 104, height: 104)
                    .overlay(Circle().strokeBorder(AppColors.border, lineWidth: 1))
                Image(systemName: systemImage)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .symbolEffect(.bounce, options: .nonRepeating, value: breathe)
            }
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            }

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                Text(description)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.md)

            Button {
                HapticManager.lightImpact()
                onAction()
            } label: {
                Label(actionText, systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 320)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "Wake up with purpose",
        description: "Alarmed only stops when you prove you're awake.",
        actionText: "Create your first alarm",
        systemImage: "alarm.fill"
    ) {}
    .preferredColorScheme(.dark)
    .background(AppColors.background)
}
