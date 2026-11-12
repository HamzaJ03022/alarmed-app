import SwiftUI
import RevenueCat

/// The hard paywall. Shown fullscreen whenever `alarmed_pro` is inactive —
/// there is no dismiss or skip: a subscription (or eligible trial) is the only
/// way in. Also presented as a dismissible sheet from Settings.
struct PaywallView: View {
    /// The fullscreen gate cannot be closed; the Settings sheet can.
    var canDismiss: Bool = false

    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showManageAlarms = false
    @State private var selectedPackage: Package? = nil

    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://alarmed.rork.app")!

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                // Soft blue glow behind the emblem.
                RadialGradient(
                    colors: [AppColors.primary.opacity(0.22), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Existing alarms") { showManageAlarms = true }
                            .font(.footnote.weight(.medium))
                    }
                }
            }
            .navigationDestination(isPresented: $showManageAlarms) {
                ManageAlarmsLockedView()
            }
            .alert(
                "Restore Purchases",
                isPresented: .init(
                    get: { store.restoreMessage != nil },
                    set: { if !$0 { store.restoreMessage = nil } }
                )
            ) {
                Button("OK") {}
            } message: {
                Text(store.restoreMessage ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        if store.isLoadingOfferings && store.packages.isEmpty {
            VStack(spacing: Spacing.md) {
                ProgressView()
                Text("Loading plans…")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColors.textSecondary)
            }
        } else if store.packages.isEmpty {
            // No products yet (store not configured / Paid Apps Agreement
            // pending): never a way in — retry + the always-on legal links.
            VStack(spacing: Spacing.md) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.textSecondary)
                Text(store.lastCheckFailed ? "Couldn't check your subscription" : "Plans are unavailable right now")
                    .font(.headline)
                    .foregroundStyle(AppColors.text)
                if store.lastCheckFailed {
                    Text("Check your connection and try again.")
                        .font(AppFont.rowDetail)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Button("Try again") {
                    Task {
                        await store.loadOfferings()
                        await store.refresh()
                        if store.isPro { return }
                        selectDefault()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
            .padding(Spacing.lg)
            legalFooter
        } else {
            planList
        }
    }

    // MARK: - Plans

    private var planList: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                    .padding(.top, Spacing.md)

                VStack(spacing: Spacing.sm) {
                    ForEach(orderedPlans, id: \.package.id) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: isSelected(plan),
                            isTrialEligible: store.isTrialEligible(plan.package)
                        ) {
                            HapticManager.lightImpact()
                            selectedPackage = plan.package
                        }
                    }
                }

                purchaseButton

                if store.lastCheckFailed {
                    Text("Couldn't verify your subscription just now — your access from the last check is still in effect.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.warning)
                        .multilineTextAlignment(.center)
                }

                termsCaption
                    .padding(.top, Spacing.xxs)

                manageAlarmsLink

                legalFooter
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .task(id: store.packages.map(\.id)) { selectDefault() }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .shadow(color: AppColors.primary.opacity(0.35), radius: 24, y: 10)
                .accessibilityHidden(true)

            Text("Alarmed Pro")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.text)

            Text("Wake up, or the alarm won't stop.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                benefitRow("checkmark.seal.fill", "Challenges that make sure you're really up")
                benefitRow("sun.max.fill", "Wake-up check-in — \"are you awake?\" nudges")
                benefitRow("alarm.waves.left.and.right.fill", "System alarms with automatic backups")
            }
            .padding(.top, Spacing.xs)
        }
    }

    private func benefitRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.text)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Purchase

    private var purchaseButton: some View {
        let plan = selectedPlan
        return Button {
            guard let package = selectedPackage else { return }
            Task { await store.purchase(package) }
        } label: {
            HStack(spacing: Spacing.xs) {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(ctaLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .disabled(store.isPurchasing || selectedPackage == nil)
        .accessibilityLabel("\(ctaLabel), \(plan?.planTitle ?? "plan")")
    }

    private var ctaLabel: String {
        guard let plan = selectedPlan else { return "Subscribe" }
        return store.isTrialEligible(plan.package) ? "Start 7 days free" : "Subscribe"
    }

    /// Honest, per-plan terms. Only promises a trial when RevenueCat says this
    /// user is eligible for the introductory offer.
    private var termsCaption: some View {
        let text: String = {
            guard let plan = selectedPlan else {
                return "Auto-renewing subscription. Cancel anytime in Settings › Apple Account › Subscriptions."
            }
            let price = plan.package.storeProduct.localizedPriceString
            let period = plan.periodNoun
            if store.isTrialEligible(plan.package) {
                return "7 days free, then \(price) every \(period). Auto-renews until cancelled. Cancel at least 24 hours before renewal in Settings › Apple Account › Subscriptions."
            }
            return "\(price) every \(period), billed automatically until cancelled. Cancel anytime in Settings › Apple Account › Subscriptions."
        }()
        return Text(text)
            .font(AppFont.caption)
            .foregroundStyle(AppColors.inactive)
            .multilineTextAlignment(.center)
    }

    private var manageAlarmsLink: some View {
        Button {
            showManageAlarms = true
        } label: {
            Text("Existing alarms still ring — manage them")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .opacity(viewModel.alarms.isEmpty ? 0 : 1)
        .disabled(viewModel.alarms.isEmpty)
    }

    private var legalFooter: some View {
        HStack(spacing: Spacing.md) {
            Button("Restore Purchases") {
                Task { await store.restore() }
            }
            Link("Terms of Use", destination: eulaURL)
            Link("Privacy Policy", destination: privacyURL)
        }
        .font(.footnote)
        .foregroundStyle(AppColors.primary)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Plan mapping

    struct PlanCardModel {
        let package: Package
        let planTitle: String
        let periodNoun: String
        let priceLine: String
        let detailLine: String?
        let badge: String?
    }

    /// Annual first (best value), then monthly, then weekly — whatever the
    /// offering contains.
    private var orderedPlans: [PlanCardModel] {
        let models = store.packages.compactMap(mapPlan)
        return models.sorted { rank($0.package) < rank($1.package) }
    }

    private func rank(_ package: Package) -> Int {
        switch package.packageType {
        case .annual: 0
        case .monthly: 1
        default: 2
        }
    }

    private func mapPlan(_ package: Package) -> PlanCardModel? {
        let product = package.storeProduct
        let price = product.localizedPriceString
        let badge: String?
        let title: String
        let periodNoun: String
        let detail: String?

        switch package.packageType {
        case .annual:
            title = "Annual"
            periodNoun = "year"
            badge = "Best value"
            // Per-week cost from the live price — never a hardcoded number.
            detail = "\(Self.money(product.price / 52, currency: product.currencyCode)) / week"
        case .monthly:
            title = "Monthly"
            periodNoun = "month"
            badge = nil
            detail = nil
        case .weekly:
            title = "Weekly"
            periodNoun = "week"
            badge = nil
            detail = nil
        default:
            // Unknown period: still show it, named after its localized title.
            title = product.localizedTitle
            periodNoun = "period"
            badge = nil
            detail = nil
        }
        return PlanCardModel(
            package: package,
            planTitle: title,
            periodNoun: periodNoun,
            priceLine: "\(price) / \(periodNoun)",
            detailLine: detail,
            badge: badge
        )
    }

    private var selectedPlan: PlanCardModel? {
        guard let selectedPackage else { return nil }
        return orderedPlans.first { $0.package.id == selectedPackage.id }
    }

    private func isSelected(_ plan: PlanCardModel) -> Bool {
        selectedPackage?.id == plan.package.id
    }

    /// Annual is pre-selected as the default choice.
    private func selectDefault() {
        guard selectedPackage == nil else { return }
        let preferred = orderedPlans.first { $0.package.packageType == .annual }
            ?? orderedPlans.first
        selectedPackage = preferred?.package
    }

    private static func money(_ amount: Decimal, currency: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

// MARK: - Plan card

private struct PlanCard: View {
    let plan: PaywallView.PlanCardModel
    let isSelected: Bool
    let isTrialEligible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.inactive)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Spacing.xs) {
                        Text(plan.planTitle)
                            .font(.headline)
                            .foregroundStyle(AppColors.text)
                        if isTrialEligible {
                            Text("7 days free")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.primarySoft, in: Capsule())
                        }
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.success, in: Capsule())
                        }
                    }
                    Text(plan.priceLine)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    if let detail = plan.detailLine {
                        Text(detail)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.success)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.primary : AppColors.divider, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(PressableStyle(scale: 0.99))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plan.planTitle), \(plan.priceLine)\(plan.badge.map { ", \($0)" } ?? "")\(isTrialEligible ? ", 7 days free trial" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Gate") {
    PaywallView()
        .environment(AlarmsViewModel())
        .environment(SubscriptionStore.shared)
}
