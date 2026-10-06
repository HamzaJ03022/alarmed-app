import SwiftUI

@main
struct AlarmedIOSApp: App {
    @State private var viewModel = AlarmsViewModel()

    init() {
        // Notification permission is requested from the onboarding
        // "Enable Alarms" button, never automatically at launch.
        setupTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
                .onReceive(
                    NotificationCenter.default.publisher(for: .alarmTriggered)
                ) { notification in
                    if let alarmId = notification.userInfo?["alarmId"] as? String {
                        viewModel.activeAlarmId = alarmId
                    }
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
