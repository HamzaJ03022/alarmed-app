import Combine
import SwiftUI

@main
struct AlarmedIOSApp: App {
    @State private var viewModel = AlarmsViewModel()
    @State private var ringingMonitor: Task<Void, Never>? = nil

    init() {
        // Notification permission is requested from the onboarding
        // "Enable Alarms" button, never automatically at launch.
        CrashGuard.inspectPreviousSession()
        CrashGuard.begin(.launch)
        setupTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
                .onReceive(
                    // Posters (App Intents, notification delegate) may run off
                    // the main thread; state updates must happen on main.
                    NotificationCenter.default.publisher(for: .alarmTriggered)
                        .receive(on: DispatchQueue.main)
                ) { notification in
                    if let alarmId = notification.userInfo?["alarmId"] as? String {
                        viewModel.handleAlarmTriggered(systemId: alarmId)
                    }
                }
                .task {
                    // AlarmKit: surface in-app ringing when a system alarm fires
                    // while the app is running.
                    if #available(iOS 26.0, *), ringingMonitor == nil {
                        ringingMonitor = AlarmKitScheduler.observeRinging()
                    }
                    // Launched via the AlarmKit alarm UI (Done or Challenge
                    // button): route straight to the ringing screen. Only a
                    // fresh marker routes — a stale one is a leftover from a
                    // challenge that already finished, not a ring to replay.
                    if let pending = AlarmedPendingAlarm.consumeFresh() {
                        viewModel.handleAlarmTriggered(systemId: pending)
                    }
                    try? await Task.sleep(for: .seconds(4))
                    CrashGuard.end(.launch)
                }
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Matches the near-black canvas (#0A0A0C) with a hairline top edge.
        appearance.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.047, alpha: 1)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.07)
        // Readable inactive tint (#8E8E93, ~6:1) and the blue accent when selected.
        let inactive = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
        let accent = UIColor(red: 0.31, green: 0.514, blue: 1.0, alpha: 1) // #4F83FF
        let item = UITabBarItemAppearance()
        item.normal.iconColor = inactive
        item.normal.titleTextAttributes = [.foregroundColor: inactive]
        item.selected.iconColor = accent
        item.selected.titleTextAttributes = [.foregroundColor: accent]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
