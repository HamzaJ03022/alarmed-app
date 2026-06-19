import SwiftUI

struct EmptyStateView: View {
    let title: String
    let description: String
    let actionText: String
    let systemImage: String
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                Text(description)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onAction) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                    Text(actionText)
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 30))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
            }
        }
        .padding(24)
    }
}

#Preview {
    EmptyStateView(
        title: "No Alarms Set",
        description: "Create your first alarm to start waking up on time.",
        actionText: "Create Alarm",
        systemImage: "alarm.fill"
    ) {}
    .preferredColorScheme(.dark)
    .background(AppColors.background)
}
