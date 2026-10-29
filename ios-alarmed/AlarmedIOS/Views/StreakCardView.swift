import SwiftUI

struct StreakCardView: View {
    let streak: Int
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 56

    private var message: String {
        switch streak {
        case 0: return "Start your streak by waking up on time!"
        case 1: return "Great start! Keep it going tomorrow."
        case 2..<5: return "You're building momentum!"
        case 5..<10: return "Impressive streak! You're developing a habit."
        default: return "Amazing discipline! You're a wake-up champion!"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Current streak", systemImage: "flame.fill")
                .font(AppFont.sectionLabel)
                .textCase(.uppercase)
                .tracking(0.7)
                .foregroundStyle(AppColors.warning)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("\(streak)")
                    .font(.system(size: numberSize, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.text)
                    .contentTransition(.numericText(value: Double(streak)))
                Text(streak == 1 ? "day" : "days")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Text(message)
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card + 4, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StreakCardView(streak: 7)
        .preferredColorScheme(.dark)
        .padding()
        .background(AppColors.background)
}
