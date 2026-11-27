import SwiftUI

#if DEBUG && targetEnvironment(simulator)
/// App Store screenshot scenario, driven by launch arguments
/// (-RORK_SCREENSHOT_SCENARIO app-store -RORK_SCREENSHOT_TARGET <target>).
/// Compiled only into simulator debug builds; it never ships.
///
/// Targets: alarms (default), phrase, questions, check-in, paywall.
enum ScreenshotMode {
    static var isAppStore: Bool {
        UserDefaults.standard.string(forKey: "RORK_SCREENSHOT_SCENARIO") == "app-store"
    }

    static var target: String? {
        guard isAppStore else { return nil }
        return UserDefaults.standard.string(forKey: "RORK_SCREENSHOT_TARGET")
    }

    private static let phraseAlarmId = "screenshot-gym"
    private static let questionsAlarmId = "screenshot-lecture"

    /// Seeds deterministic demo alarms and routes to the target screen.
    /// Returns true when the scenario is active (the caller then skips the
    /// live entitlement check for Pro screens).
    @MainActor
    static func apply(viewModel: AlarmsViewModel, store: SubscriptionStore) -> Bool {
        guard isAppStore else { return false }

        viewModel.hasSeenOnboarding = true
        viewModel.alarms = [
            Alarm(
                id: phraseAlarmId,
                time: "06:30",
                label: "Gym before work",
                repeatDays: ["mon", "tue", "wed", "thu", "fri"],
                dismissalMode: "phrase",
                dismissPhrase: "I am awake and ready to win the day.",
                sound: "rising_sun",
                checkInEnabled: true,
                checkInDelayMinutes: 10
            ),
            Alarm(
                id: questionsAlarmId,
                time: "07:45",
                label: "Morning lecture",
                repeatDays: ["mon", "wed", "fri"],
                questionCount: 3,
                questionDifficulty: "medium",
                checkInEnabled: true
            ),
            Alarm(
                id: "screenshot-run",
                time: "08:30",
                label: "Weekend long run",
                repeatDays: ["sat", "sun"],
                questionCount: 2,
                questionDifficulty: "easy",
                sound: "gentle_morning"
            ),
            Alarm(
                id: "screenshot-flight",
                time: "04:50",
                label: "Flight to Lisbon",
                isActive: false,
                questionCount: 5,
                questionDifficulty: "hard",
                sound: "siren"
            )
        ]

        let iso = ISO8601DateFormatter()
        let calendar = Calendar.current
        viewModel.history = (0..<6).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return AlarmHistory(
                id: "screenshot-history-\(offset)",
                alarmId: offset.isMultiple(of: 2) ? phraseAlarmId : questionsAlarmId,
                date: iso.string(from: day),
                wakeUpTime: iso.string(from: day),
                questionsAnswered: 3,
                questionsCorrect: 3
            )
        }

        switch target {
        case "paywall":
            // A fresh simulator has no entitlement: the real hard paywall
            // shows with the live offering.
            store.start()
        case "phrase":
            store.applyScreenshotState(isPro: true)
            viewModel.activeAlarmId = phraseAlarmId
        case "questions":
            store.applyScreenshotState(isPro: true)
            viewModel.activeAlarmId = questionsAlarmId
        case "check-in":
            store.applyScreenshotState(isPro: true)
            viewModel.activeCheckInAlarmId = phraseAlarmId
        default:
            store.applyScreenshotState(isPro: true)
        }
        return true
    }
}

/// Invisible markers the screenshot recorder waits for.
struct ScreenshotReadyMarker: View {
    var body: some View {
        if ScreenshotMode.isAppStore {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .frame(width: 2, height: 2)
                    .accessibilityElement()
                    .accessibilityIdentifier("rork.screenshot.ready.app-store")
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .frame(width: 2, height: 2)
                    .accessibilityElement()
                    .accessibilityLabel("rork.screenshot.target.\(ScreenshotMode.target ?? "alarms")")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
        }
    }
}
#endif
