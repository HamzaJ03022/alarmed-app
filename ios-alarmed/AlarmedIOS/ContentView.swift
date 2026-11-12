import SwiftUI

struct ContentView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        ZStack {
            if !store.hasResolved {
                // First entitlement check in flight — never render a guess.
                ProLoadingView()
            } else if viewModel.hasSeenOnboarding {
                if store.isPro {
                    TabView {
                        AlarmsListView()
                            .tabItem {
                                Image(systemName: "alarm.fill")
                                Text("Alarms")
                            }
                        HistoryListView()
                            .tabItem {
                                Image(systemName: "chart.bar.fill")
                                Text("History")
                            }
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                    }
                    .tint(AppColors.primary)
                } else {
                    // Hard paywall: onboarding done, no active entitlement.
                    // No skip, no free tier — only a trial or purchase unlocks.
                    PaywallView()
                }
            } else {
                OnboardingView()
            }

            if let alarmId = viewModel.activeAlarmId {
                if let alarm = viewModel.alarms.first(where: { $0.id == alarmId }) {
                    AlarmRingingView(alarm: alarm)
                        .transition(.move(edge: .bottom))
                }
            }

            if let checkInId = viewModel.activeCheckInAlarmId,
               let alarm = viewModel.alarms.first(where: { $0.id == checkInId }) {
                AreYouAwakeView(alarm: alarm)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(duration: 0.35), value: store.isPro)
    }
}

/// Shown while the first entitlement check resolves — brief by design, and it
/// never resolves to "pro" on a failed check.
private struct ProLoadingView: View {
    var body: some View {
        AppColors.background.ignoresSafeArea()
            .overlay {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.primary)
                    ProgressView()
                }
            }
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AlarmsViewModel())
        .environment(SubscriptionStore.shared)
        .preferredColorScheme(.dark)
}
