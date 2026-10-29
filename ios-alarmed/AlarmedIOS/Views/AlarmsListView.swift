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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.alarms) { alarm in
                                AlarmItemView(alarm: alarm)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 100)
                    }
                    .overlay(alignment: .bottom) {
                        if let message = viewModel.saveConfirmationMessage {
                            saveToast(message)
                                .id(message)
                                .task {
                                    try? await Task.sleep(for: .seconds(2.5))
                                    if viewModel.saveConfirmationMessage == message {
                                        viewModel.saveConfirmationMessage = nil
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.35), value: viewModel.saveConfirmationMessage)

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
    @ViewBuilder
    private func saveToast(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.text)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppColors.card, in: Capsule())
        .overlay(Capsule().stroke(AppColors.success.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        .padding(.bottom, 110)
    }
}

#Preview {
    AlarmsListView()
        .environment(AlarmsViewModel())
        .preferredColorScheme(.dark)
}
