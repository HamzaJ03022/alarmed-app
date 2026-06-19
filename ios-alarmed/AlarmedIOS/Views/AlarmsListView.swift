import SwiftUI

struct AlarmsListView: View {
    @Environment(AlarmsViewModel.self) private var viewModel
    @State private var showCreateAlarm = false
    @State private var alarmChecker: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.alarms.isEmpty {
                    EmptyStateView(
                        title: "No Alarms Set",
                        description: "Create your first alarm to start waking up on time and building better habits.",
                        actionText: "Create Alarm",
                        systemImage: "alarm.fill"
                    ) {
                        showCreateAlarm = true
                    }
                } else {
                    VStack(spacing: 0) {
                        WarningBanner()

                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.alarms) { alarm in
                                    AlarmItemView(alarm: alarm)
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 100)
                        }
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showCreateAlarm = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundStyle(AppColors.text)
                                    .frame(width: 64, height: 64)
                                    .background(AppColors.primary, in: Circle())
                                    .shadow(color: AppColors.primary.opacity(0.4), radius: 16, y: 8)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateAlarm) {
                CreateAlarmView()
            }
        }
    }
}

private struct WarningBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.warning)
            Text("Keep the app running for alarms to work")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.warning)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.warningBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.warning)
                .frame(height: 1)
        }
    }
}

#Preview {
    AlarmsListView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
