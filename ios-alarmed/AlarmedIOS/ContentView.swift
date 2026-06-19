import SwiftUI

struct ContentView: View {
    @Environment(AlarmsViewModel.self) private var viewModel

    var body: some View {
        ZStack {
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

            if let alarmId = viewModel.activeAlarmId {
                if let alarm = viewModel.alarms.first(where: { $0.id == alarmId }) {
                    AlarmRingingView(alarm: alarm)
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
