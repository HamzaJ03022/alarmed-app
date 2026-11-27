import Foundation
import Observation
import os
import RevenueCat

/// Single source of truth for Alarmed Pro access.
///
/// Everything in the app asks this store one question — "is `alarmed_pro`
/// active?" — and never inspects product identifiers itself. State comes only
/// from RevenueCat's entitlements: purchase, restore, renewal, grace period
/// and billing retry are all reflected by RevenueCat before this store sees
/// anything.
///
/// Failure policy: a failed status check never *grants* access. The last
/// verified status (persisted) is reused until a fresh check succeeds; with no
/// verified status the app stays locked with a retry affordance.
@Observable
@MainActor
final class SubscriptionStore {

    static let entitlementId = "alarmed_pro"
    static let shared = SubscriptionStore()

    // MARK: - Observable state

    /// True once the first authoritative answer (fresh or RevenueCat-cached)
    /// has landed. The launch gate shows a loading state until then.
    private(set) var hasResolved = false
    /// The one flag the whole app gates on.
    private(set) var isPro = false
    private(set) var entitlementExpiration: Date? = nil
    private(set) var entitlementWillRenew = false
    private(set) var activeProductId: String? = nil
    /// True when the latest status check failed (paywall shows "couldn't check").
    private(set) var lastCheckFailed = false

    // Paywall inputs
    private(set) var packages: [Package] = []
    private(set) var isLoadingOfferings = false
    private(set) var offeringsFailed = false
    /// Package identifier -> eligible for the introductory free trial.
    private(set) var introEligibility: [String: Bool] = [:]

    var isPurchasing = false
    private(set) var isRestoring = false
    /// User-facing one-line result of restore ("nothing to restore") — nil otherwise.
    var restoreMessage: String? = nil

    // MARK: - Private

    private let logger = Logger(subsystem: "com.nyytech.alarmed", category: "subscription")
    private let cachedProKey = "alarmed_subscription_verified_pro"
    private let cachedDateKey = "alarmed_subscription_verified_date"
    private var listening = false

    private var defaults: UserDefaults { .standard }

    // MARK: - Lifecycle

    /// Call once from App.init(), before any UI exists.
    static func configureSDK() {
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.RORK_PUBLIC_REVENUECAT_TEST_API_KEY)
        #else
        Purchases.configure(withAPIKey: Config.RORK_PUBLIC_REVENUECAT_IOS_API_KEY)
        #endif
    }

    /// Call once from the root view's .task. Installs the customer-info
    /// listener (which also delivers RevenueCat's cached info immediately)
    /// and performs a fresh status check.
    func start() {
        guard !listening else { return }
        listening = true
        // Seed with the last verified status so the gate renders instantly.
        isPro = defaults.bool(forKey: cachedProKey)
        if isPro { hasResolved = true }

        Task {
            for await info in Purchases.shared.customerInfoStream {
                apply(info)
            }
        }
        Task { await refresh() }
        Task { await loadOfferings() }
    }

    #if DEBUG && targetEnvironment(simulator)
    /// App Store screenshot scenario only: show a resolved state without the
    /// live entitlement listener.
    func applyScreenshotState(isPro: Bool) {
        self.isPro = isPro
        hasResolved = true
    }
    #endif

    // MARK: - Status checks

    /// Fresh entitlement check: launch, foreground, restore, purchase.
    /// Never throws into the UI — on failure the last verified state stands.
    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            lastCheckFailed = false
            apply(info)
        } catch {
            logger.error("Status check failed (\(error.localizedDescription, privacy: .public)); keeping last verified state")
            lastCheckFailed = true
            hasResolved = true
        }
    }

    /// Run right before a Pro action (create / edit / re-enable an alarm).
    /// Returns whether the entitlement is still active after the check.
    func refreshForProAction() async -> Bool {
        await refresh()
        return isPro
    }

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementId]
        isPro = entitlement?.isActive == true
        entitlementExpiration = entitlement?.expirationDate
        entitlementWillRenew = entitlement?.willRenew == true
        activeProductId = entitlement?.productIdentifier
        hasResolved = true

        // Persist the last verified answer for offline launches.
        defaults.set(isPro, forKey: cachedProKey)
        defaults.set(Date().timeIntervalSince1970, forKey: cachedDateKey)

        if isPro {
            logger.info("Pro active (product: \(entitlement?.productIdentifier ?? "?", privacy: .public), renews: \(self.entitlementWillRenew))")
        }
    }

    // MARK: - Offerings

    func loadOfferings() async {
        isLoadingOfferings = true
        offeringsFailed = false
        defer { isLoadingOfferings = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            let current = offerings.current
            packages = current?.availablePackages ?? []
            offeringsFailed = packages.isEmpty
            if packages.isEmpty {
                logger.error("Current offering has no packages")
            }
            await checkTrialEligibility()
        } catch {
            offeringsFailed = true
            logger.error("Offerings failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func checkTrialEligibility() async {
        guard !packages.isEmpty else { return }
        var result: [String: Bool] = [:]
        for package in packages {
            let status = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: package.storeProduct)
            result[package.identifier] = status == .eligible
        }
        introEligibility = result
    }

    /// Whether the given package promises a trial for THIS user. Drives both
    /// the CTA label and the honest terms line — a non-eligible user never
    /// sees the words "free trial".
    func isTrialEligible(_ package: Package) -> Bool {
        introEligibility[package.identifier] == true && trialLength(package) != nil
    }

    /// The free-trial length exactly as configured in App Store Connect,
    /// e.g. "3 days" or "1 week". Nil when the product has no free trial.
    func trialLength(_ package: Package) -> String? {
        guard let intro = package.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let total = intro.subscriptionPeriod.value * max(intro.numberOfPeriods, 1)
        guard total > 0 else { return nil }
        let unit: String
        switch intro.subscriptionPeriod.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: return nil
        }
        return "\(total) \(unit)\(total == 1 ? "" : "s")"
    }

    // MARK: - Purchase & restore

    func purchase(_ package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return }
            apply(result.customerInfo)
            if isPro {
                HapticManager.successNotification()
            }
        } catch ErrorCode.paymentPendingError {
            // Ask to Buy / extra auth: not a failure. Entitlement arrives via
            // the customer-info stream once approved.
            restoreMessage = "Your request was sent for approval. Access unlocks once it's approved."
        } catch ErrorCode.purchaseCancelledError {
            return
        } catch {
            restoreMessage = error.localizedDescription
        }
    }

    func restore() async {
        isRestoring = true
        restoreMessage = nil
        defer { isRestoring = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if !isPro {
                restoreMessage = "No active subscription was found for this Apple Account."
            }
        } catch {
            restoreMessage = error.localizedDescription
        }
    }

    // MARK: - Display helpers (used by Settings and the paywall footer)

    /// "Alarmed Pro · renews 12 Nov" / "· expires 12 Nov" / nil when locked.
    var proStatusLine: String? {
        guard isPro else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if entitlementWillRenew {
            return entitlementExpiration.map { "Renews \(formatter.string(from: $0))" }
        }
        return entitlementExpiration.map { "Access until \(formatter.string(from: $0))" }
    }
}
