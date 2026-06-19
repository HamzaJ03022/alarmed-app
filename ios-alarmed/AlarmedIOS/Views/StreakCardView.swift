import SwiftUI

struct StreakCardView: View {
    let streak: Int

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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.warning)
                Text("Current Streak")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.text)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppColors.warning)
                Text(streak == 1 ? "day" : "days")
                    .font(.title3)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(24)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.cardShadow, radius: 20, y: 6)
    }
}

#Preview {
    StreakCardView(streak: 7)
        .preferredColorScheme(.dark)
        .padding()
        .background(AppColors.background)
}
