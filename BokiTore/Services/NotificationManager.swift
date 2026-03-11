import UserNotifications

/// ローカル通知の管理
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - 通知許可

    /// 通知許可をリクエストする
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            #if DEBUG
            print("通知許可リクエストエラー: \(error)")
            #endif
            return false
        }
    }

    /// 現在の通知許可状態を取得する
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - 通知スケジュール

    /// デイリーリマインダーを設定する（毎日指定時間に通知）
    func scheduleDailyReminder(hour: Int, minute: Int, dailyGoal: Int) {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        content.body = "今日の目標: \(dailyGoal)問に挑戦しましょう!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("デイリーリマインダー設定エラー: \(error)")
            }
            #endif
        }
    }

    /// ストリーク途切れ警告を設定する（毎晩21時）
    func scheduleStreakWarning() {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        content.body = "今日まだ勉強していません。連続学習記録が途切れそうです!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_warning",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("ストリーク警告設定エラー: \(error)")
            }
            #endif
        }
    }

    /// 全ての通知を削除する
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// デイリーリマインダーのみ削除する
    func removeDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }

    /// ストリーク警告のみ削除する
    func removeStreakWarning() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["streak_warning"])
    }
}
