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
                    // Launched via the AlarmKit alarm UI (OpenChallengeIntent):
                    // route straight to the ringing screen with the challenge.
                    if let pending = UserDefaults.standard.string(forKey: AlarmedPendingAlarm.key) {
                        UserDefaults.standard.removeObject(forKey: AlarmedPendingAlarm.key)
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
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
