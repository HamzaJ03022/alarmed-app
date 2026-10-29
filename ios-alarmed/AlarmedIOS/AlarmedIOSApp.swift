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
        appearance.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        // Brighter inactive tint so unreadable #666666 labels get usable contrast
        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1) // #8E8E93
        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
        ]
        appearance.stackedLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
