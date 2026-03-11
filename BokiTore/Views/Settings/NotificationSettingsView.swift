import SwiftUI
import SwiftData

/// 通知設定画面（mikan式の複数通知スロット対応）
struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var studyPlans: [StudyPlan]
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = false
    @AppStorage("isStreakWarningEnabled") private var isStreakWarningEnabled = false
    @State private var notificationSlots: [NotificationSlot] = NotificationSlot.defaults
    @State private var permissionDenied = false
    @State private var showAddSlot = false

    /// 学習計画（1つだけ存在する想定）
    private var studyPlan: StudyPlan? {
        studyPlans.first { $0.isOnboardingCompleted }
    }

    var body: some View {
        List {
            // スマートリマインド説明
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(Color.appPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("スマートリマインド")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("学習パターンを分析して最適なタイミングで通知します")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // 学習リマインドメインスイッチ
            Section {
                Toggle("学習リマインド", isOn: $isNotificationsEnabled)
                    .onChange(of: isNotificationsEnabled) { _, newValue in
                        handleNotificationToggle(enabled: newValue)
                    }
            } header: {
                Text("デイリーリマインド")
            } footer: {
                Text("設定した時間帯に学習リマインドを送ります。")
            }

            // 通知スロット一覧（mikan式）
            if isNotificationsEnabled {
                Section {
                    ForEach(Array(notificationSlots.enumerated()), id: \.element.id) { index, slot in
                        NotificationSlotRow(
                            slot: $notificationSlots[index],
                            onChanged: { saveSlots() }
                        )
                    }
                    .onDelete { indexSet in
                        notificationSlots.remove(atOffsets: indexSet)
                        saveSlots()
                    }

                    // 追加ボタン
                    Button {
                        showAddSlot = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                            Text("通知時間を追加")
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                } header: {
                    Text("通知時間帯")
                } footer: {
                    Text("複数の時間帯を設定できます。ONにした時間帯にリマインドが届きます。")
                }
            }

            // ストリーク警告
            Section {
                Toggle("ストリーク途切れ警告", isOn: $isStreakWarningEnabled)
                    .onChange(of: isStreakWarningEnabled) { _, newValue in
                        handleStreakWarningToggle(enabled: newValue)
                    }
            } header: {
                Text("ストリーク警告")
            } footer: {
                Text("その日まだ学習していない場合のみ、21時に通知します。")
            }

            // スマート通知の内容
            if isNotificationsEnabled {
                Section {
                    SmartNotificationRow(
                        icon: "clock.badge.checkmark",
                        title: "学習リマインド",
                        description: "目標未達の日にお知らせ"
                    )
                    SmartNotificationRow(
                        icon: "arrow.counterclockwise.circle",
                        title: "復習リマインド",
                        description: "忘却曲線に基づく復習通知"
                    )
                    SmartNotificationRow(
                        icon: "chart.line.downtrend.xyaxis",
                        title: "ペースダウン通知",
                        description: "学習頻度が落ちた時にお知らせ"
                    )
                    SmartNotificationRow(
                        icon: "hand.thumbsup.fill",
                        title: "励まし通知",
                        description: "正答率が下がった時の応援"
                    )
                } header: {
                    Text("スマート通知の内容")
                }
            }

            // 許可状態の警告
            if permissionDenied {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("通知が許可されていません。iOSの設定から許可してください。")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("通知設定")
        .onAppear { loadCurrentSettings() }
        .sheet(isPresented: $showAddSlot) {
            AddNotificationSlotSheet(
                onAdd: { newSlot in
                    notificationSlots.append(newSlot)
                    saveSlots()
                }
            )
        }
    }

    // MARK: - ロジック

    /// 現在の設定を読み込む
    private func loadCurrentSettings() {
        if let plan = studyPlan {
            notificationSlots = plan.getNotificationSlots()
        }

        // 通知許可状態を確認
        Task {
            let status = await SmartReminderManager.shared.checkPermissionStatus()
            await MainActor.run {
                permissionDenied = (status == .denied)
            }
        }
    }

    /// スロットの変更を保存して通知を再スケジュール
    private func saveSlots() {
        studyPlan?.setNotificationSlots(notificationSlots)
        // preferredHour/Minuteも最初の有効スロットに同期
        if let firstEnabled = notificationSlots.first(where: { $0.isEnabled }) {
            studyPlan?.preferredHour = firstEnabled.hour
            studyPlan?.preferredMinute = firstEnabled.minute
        }
        triggerReschedule()
    }

    /// 通知トグルの変更を処理
    private func handleNotificationToggle(enabled: Bool) {
        if enabled {
            Task {
                let granted = await SmartReminderManager.shared.requestPermission()
                await MainActor.run {
                    if granted {
                        triggerReschedule()
                    } else {
                        isNotificationsEnabled = false
                        permissionDenied = true
                    }
                }
            }
        } else {
            SmartReminderManager.shared.removeDailyReminder()
        }
    }

    /// ストリーク警告トグルの変更を処理
    private func handleStreakWarningToggle(enabled: Bool) {
        if enabled {
            Task {
                let granted = await SmartReminderManager.shared.requestPermission()
                await MainActor.run {
                    if granted {
                        triggerReschedule()
                    } else {
                        isStreakWarningEnabled = false
                        permissionDenied = true
                    }
                }
            }
        } else {
            SmartReminderManager.shared.removeStreakWarning()
        }
    }

    /// スマート通知を再スケジュールする
    private func triggerReschedule() {
        SmartReminderManager.shared.rescheduleSmartNotifications(modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .modelContainer(.preview)
}
