import SwiftUI

struct MotivationalQuoteView: View {
    let quote: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            cardQuote
            congratulationText
            continueButton
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private var cardQuote: some View {
        VStack(spacing: 16) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.primary)

            Text(quote)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.primary)
                .scaleEffect(y: -1)
        }
        .padding(32)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppColors.cardShadow, radius: 24, y: 8)
    }

    private var congratulationText: some View {
        Text("Congratulations on waking up!")
            .font(.title3)
            .foregroundStyle(AppColors.primary)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Start My Day")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 48)
                .padding(.vertical, 18)
                .background(AppColors.primary, in: Capsule())
                .shadow(color: AppColors.primary.opacity(0.4), radius: 16, y: 8)
        }
    }
}

#Preview {
    MotivationalQuoteView(quote: "Rise and shine! Today is full of possibilities.") {}
        .preferredColorScheme(.dark)
}
