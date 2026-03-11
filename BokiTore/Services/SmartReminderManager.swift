import Foundation
import UserNotifications
import SwiftData

/// 学習曲線に基づくスマートリマインド管理
/// アプリがフォアグラウンドに来るたびに学習パターンを分析し、
/// 最適な通知を再スケジュールする
class SmartReminderManager {
    static let shared = SmartReminderManager()
    private init() {}

    /// 通知の識別子プレフィックス
    private enum Identifier {
        static let dailyReminder = "smart_daily"
        static let dailySlotPrefix = "smart_daily_slot_"
        static let streakWarning = "smart_streak"
        static let reviewDue = "smart_review"
        static let activityDrop = "smart_activity_drop"
        static let encouragement = "smart_encouragement"
    }

    /// 現在スケジュール済みのスロット通知ID（削除用に追跡）
    private var scheduledSlotIds: [String] = []

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

    // MARK: - スマートスケジュール（メインエントリポイント）

    /// 学習データを分析して最適な通知をスケジュールする
    /// アプリがフォアグラウンドに来るたびに呼ばれる
    func rescheduleSmartNotifications(modelContext: ModelContext) {
        // 通知設定がOFFなら何もしない
        let isEnabled = UserDefaults.standard.bool(forKey: "isNotificationsEnabled")
        let isStreakEnabled = UserDefaults.standard.bool(forKey: "isStreakWarningEnabled")

        guard isEnabled || isStreakEnabled else { return }

        // 全スマート通知を一度クリア（再計算するため）
        removeAllSmartNotifications()

        do {
            // データ取得
            let studyPlan = try fetchStudyPlan(modelContext: modelContext)
            let recentProgress = try fetchRecentProgress(modelContext: modelContext, days: 14)
            let todayProgress = try fetchTodayProgress(modelContext: modelContext)
            let reviewItems = try fetchDueReviewItems(modelContext: modelContext)
            let streaks = try fetchRecentStreaks(modelContext: modelContext, days: 7)

            // 今日学習済みかどうか
            let hasStudiedToday = !todayProgress.isEmpty

            // 1. デイリーリマインド（複数スロット対応）
            if isEnabled {
                let dailyGoal = studyPlan?.dailyGoal ?? 10
                let todayCount = todayProgress.count

                // まだ今日の目標を達成していない場合のみ
                if todayCount < dailyGoal {
                    // 複数通知スロットからスケジュール
                    let slots = studyPlan?.getNotificationSlots() ?? NotificationSlot.defaults
                    let enabledSlots = slots.filter { $0.isEnabled }

                    if enabledSlots.isEmpty {
                        // スロットが1つもONでない場合、従来の最適時間で通知
                        let optimalTime = analyzeOptimalStudyTime(
                            recentProgress: recentProgress,
                            studyPlan: studyPlan
                        )
                        scheduleDailyReminder(
                            hour: optimalTime.hour,
                            minute: optimalTime.minute,
                            dailyGoal: dailyGoal,
                            todayCount: todayCount
                        )
                    } else {
                        // 各有効スロットに個別の通知をスケジュール
                        for slot in enabledSlots {
                            scheduleDailyReminderForSlot(
                                slot: slot,
                                dailyGoal: dailyGoal,
                                todayCount: todayCount
                            )
                        }
                    }
                }
            }

            // 2. ストリーク警告（未学習時のみ）
            if isStreakEnabled && !hasStudiedToday {
                let currentStreak = calculateCurrentStreak(streaks: streaks)
                scheduleStreakWarning(currentStreak: currentStreak)
            }

            // 3. 復習リマインド（復習アイテムがある場合）
            if isEnabled && !reviewItems.isEmpty {
                scheduleReviewReminder(reviewCount: reviewItems.count)
            }

            // 4. 学習頻度低下アラート
            if isEnabled {
                let activityTrend = analyzeActivityTrend(recentProgress: recentProgress)
                if activityTrend == .declining {
                    scheduleActivityDropReminder()
                }
            }

            // 5. 正答率低下時の励まし
            if isEnabled {
                let accuracyTrend = analyzeAccuracyTrend(recentProgress: recentProgress)
                if accuracyTrend == .declining {
                    let weakCategory = findWeakestCategory(recentProgress: recentProgress)
                    scheduleEncouragementReminder(weakCategory: weakCategory)
                }
            }

            #if DEBUG
            print("スマート通知を再スケジュールしました")
            #endif
        } catch {
            #if DEBUG
            print("スマート通知スケジュールエラー: \(error)")
            #endif
        }
    }

    // MARK: - データ分析

    /// 最適な学習時間を分析する（直近14日の解答時間帯から推定）
    private func analyzeOptimalStudyTime(
        recentProgress: [UserProgress],
        studyPlan: StudyPlan?
    ) -> (hour: Int, minute: Int) {
        // デフォルト: 学習計画の設定時間
        let defaultHour = studyPlan?.preferredHour ?? 20
        let defaultMinute = studyPlan?.preferredMinute ?? 0

        // 十分なデータがなければデフォルト
        guard recentProgress.count >= 5 else {
            return (defaultHour, defaultMinute)
        }

        // 時間帯別の学習回数をカウント
        var hourCounts: [Int: Int] = [:]
        for progress in recentProgress {
            let hour = Calendar.current.component(.hour, from: progress.answeredAt)
            hourCounts[hour, default: 0] += 1
        }

        // 最も学習頻度が高い時間帯を特定
        guard let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return (defaultHour, defaultMinute)
        }

        // ピーク時間の10分前にリマインド（準備時間を考慮）
        let reminderMinute: Int
        let reminderHour: Int
        if defaultMinute >= 10 {
            reminderHour = peakHour
            reminderMinute = defaultMinute - 10
        } else {
            reminderHour = (peakHour - 1 + 24) % 24
            reminderMinute = 50
        }

        return (reminderHour, reminderMinute)
    }

    /// 学習活動のトレンドを分析する
    private func analyzeActivityTrend(recentProgress: [UserProgress]) -> Trend {
        let calendar = Calendar.current
        let now = Date.now

        // 直近7日 vs その前の7日を比較
        let recentWeek = recentProgress.filter {
            calendar.dateComponents([.day], from: $0.answeredAt, to: now).day ?? 0 < 7
        }
        let previousWeek = recentProgress.filter {
            let days = calendar.dateComponents([.day], from: $0.answeredAt, to: now).day ?? 0
            return days >= 7 && days < 14
        }

        // 前の週のデータがなければ判定不能
        guard !previousWeek.isEmpty else { return .stable }

        let recentDaily = Double(recentWeek.count) / 7.0
        let previousDaily = Double(previousWeek.count) / 7.0

        // 30%以上低下で「declining」判定
        if previousDaily > 0 && recentDaily / previousDaily < 0.7 {
            return .declining
        }
        return .stable
    }

    /// 正答率のトレンドを分析する
    private func analyzeAccuracyTrend(recentProgress: [UserProgress]) -> Trend {
        let calendar = Calendar.current
        let now = Date.now

        let recentWeek = recentProgress.filter {
            calendar.dateComponents([.day], from: $0.answeredAt, to: now).day ?? 0 < 7
        }
        let previousWeek = recentProgress.filter {
            let days = calendar.dateComponents([.day], from: $0.answeredAt, to: now).day ?? 0
            return days >= 7 && days < 14
        }

        guard recentWeek.count >= 5, previousWeek.count >= 5 else { return .stable }

        let recentAccuracy = Double(recentWeek.filter { $0.isCorrect }.count) / Double(recentWeek.count)
        let previousAccuracy = Double(previousWeek.filter { $0.isCorrect }.count) / Double(previousWeek.count)

        // 正答率が10ポイント以上低下で「declining」
        if previousAccuracy - recentAccuracy > 0.10 {
            return .declining
        }
        return .stable
    }

    /// 最も苦手なカテゴリを特定する（直近の問題IDから推定）
    private func findWeakestCategory(recentProgress: [UserProgress]) -> String? {
        let calendar = Calendar.current
        let now = Date.now
        let recentWeek = recentProgress.filter {
            calendar.dateComponents([.day], from: $0.answeredAt, to: now).day ?? 0 < 7
        }

        // 問題IDのプレフィックスでカテゴリ推定（例: "JE001" → "JE"）
        var categoryStats: [String: (correct: Int, total: Int)] = [:]
        for progress in recentWeek {
            let prefix = String(progress.questionId.prefix(2))
            var stats = categoryStats[prefix] ?? (0, 0)
            stats.total += 1
            if progress.isCorrect { stats.correct += 1 }
            categoryStats[prefix] = stats
        }

        // 最も正答率が低いカテゴリ（最低5問以上解いたもの）
        let weakest = categoryStats
            .filter { $0.value.total >= 5 }
            .min { lhs, rhs in
                Double(lhs.value.correct) / Double(lhs.value.total) <
                Double(rhs.value.correct) / Double(rhs.value.total)
            }

        return weakest?.key
    }

    /// 現在のストリーク日数を計算する
    private func calculateCurrentStreak(streaks: [StudyStreak]) -> Int {
        let calendar = Calendar.current
        let sorted = streaks.sorted { $0.date > $1.date }
        var streak = 0
        // 昨日から遡ってチェック（今日はまだ学習中かもしれないため）
        var checkDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now)

        for record in sorted {
            let recordDate = calendar.startOfDay(for: record.date)
            if recordDate == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if recordDate < checkDate {
                break
            }
        }
        return streak
    }

    // MARK: - 通知スケジュール

    /// デイリーリマインダー（学習パターン最適化済み）
    private func scheduleDailyReminder(hour: Int, minute: Int, dailyGoal: Int, todayCount: Int) {
        let remaining = dailyGoal - todayCount
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        if todayCount == 0 {
            content.body = "今日の目標: \(dailyGoal)問に挑戦しましょう!"
        } else {
            content.body = "あと\(remaining)問で今日の目標達成です!"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.dailyReminder,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("デイリーリマインダーエラー: \(error)") }
            #endif
        }
    }

    /// 通知スロット用のデイリーリマインダー
    private func scheduleDailyReminderForSlot(slot: NotificationSlot, dailyGoal: Int, todayCount: Int) {
        let remaining = dailyGoal - todayCount
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        if todayCount == 0 {
            content.body = "今日の目標: \(dailyGoal)問に挑戦しましょう!"
        } else {
            content.body = "あと\(remaining)問で今日の目標達成です!"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = slot.hour
        dateComponents.minute = slot.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "\(Identifier.dailySlotPrefix)\(slot.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        scheduledSlotIds.append(identifier)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("スロットリマインダーエラー(\(slot.label)): \(error)") }
            #endif
        }
    }

    /// ストリーク警告（未学習時のみ、21時に送信）
    private func scheduleStreakWarning(currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        if currentStreak > 0 {
            content.body = "\(currentStreak)日連続の記録が途切れそうです! 今日も頑張りましょう!"
        } else {
            content.body = "今日まだ勉強していません。少しだけやりませんか?"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.streakWarning,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("ストリーク警告エラー: \(error)") }
            #endif
        }
    }

    /// 復習リマインド（復習期限の問題がある場合）
    private func scheduleReviewReminder(reviewCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ - 復習"
        content.body = "\(reviewCount)件の復習問題が今日期限です。忘れる前に復習しましょう!"
        content.sound = .default

        // 朝9時に通知（学習リマインドとは別の時間帯）
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.reviewDue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("復習リマインドエラー: \(error)") }
            #endif
        }
    }

    /// 学習頻度低下アラート（翌日の昼に通知）
    private func scheduleActivityDropReminder() {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        content.body = "最近ペースが落ちています。5問だけ解いてみませんか?"
        content.sound = .default

        // 翌日の12時に通知
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = 12
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.activityDrop,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("活動低下アラートエラー: \(error)") }
            #endif
        }
    }

    /// 正答率低下時の励ましリマインド
    private func scheduleEncouragementReminder(weakCategory: String?) {
        let content = UNMutableNotificationContent()
        content.title = "簿記トレ"
        if let category = weakCategory {
            let categoryName = categoryDisplayName(for: category)
            content.body = "\(categoryName)の正答率が下がっています。復習で取り戻しましょう!"
        } else {
            content.body = "苦手な分野を復習して、正答率を上げましょう!"
        }
        content.sound = .default

        // 翌日の夕方18時に通知
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.encouragement,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("励ましリマインドエラー: \(error)") }
            #endif
        }
    }

    // MARK: - 通知削除

    /// 全スマート通知を削除する
    func removeAllSmartNotifications() {
        var idsToRemove = [
            Identifier.dailyReminder,
            Identifier.streakWarning,
            Identifier.reviewDue,
            Identifier.activityDrop,
            Identifier.encouragement
        ]
        // スロット通知IDも追加
        idsToRemove.append(contentsOf: scheduledSlotIds)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        scheduledSlotIds.removeAll()
    }

    /// デイリーリマインダーのみ削除する（スロット通知も含む）
    func removeDailyReminder() {
        var idsToRemove = [Identifier.dailyReminder]
        idsToRemove.append(contentsOf: scheduledSlotIds)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: idsToRemove)
        scheduledSlotIds.removeAll()
    }

    /// ストリーク警告のみ削除する
    func removeStreakWarning() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Identifier.streakWarning])
    }

    // MARK: - データ取得ヘルパー

    /// 学習計画を取得する
    private func fetchStudyPlan(modelContext: ModelContext) throws -> StudyPlan? {
        let descriptor = FetchDescriptor<StudyPlan>()
        let plans = try modelContext.fetch(descriptor)
        return plans.first { $0.isOnboardingCompleted }
    }

    /// 直近N日の解答履歴を取得する
    private func fetchRecentProgress(modelContext: ModelContext, days: Int) throws -> [UserProgress] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<UserProgress>(
            predicate: #Predicate<UserProgress> { $0.answeredAt >= cutoff },
            sortBy: [SortDescriptor(\.answeredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 今日の解答履歴を取得する
    private func fetchTodayProgress(modelContext: ModelContext) throws -> [UserProgress] {
        let todayStart = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<UserProgress>(
            predicate: #Predicate<UserProgress> { $0.answeredAt >= todayStart }
        )
        return try modelContext.fetch(descriptor)
    }

    /// 今日が期限の復習アイテムを取得する
    private func fetchDueReviewItems(modelContext: ModelContext) throws -> [ReviewItem] {
        let todayEnd = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate<ReviewItem> { $0.nextReviewDate < todayEnd }
        )
        return try modelContext.fetch(descriptor)
    }

    /// 直近N日のストリーク記録を取得する
    private func fetchRecentStreaks(modelContext: ModelContext, days: Int) throws -> [StudyStreak] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<StudyStreak>(
            predicate: #Predicate<StudyStreak> { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - ヘルパー

    /// トレンド判定
    enum Trend {
        case stable
        case declining
    }

    /// カテゴリプレフィックスから表示名を取得する
    private func categoryDisplayName(for prefix: String) -> String {
        // QuestionBankのIDプレフィックスに合わせる
        switch prefix {
        case "JE": return "仕訳"
        case "TB": return "試算表"
        case "FS": return "財務諸表"
        case "AC": return "勘定科目"
        case "TM": return "用語"
        default: return "簿記"
        }
    }
}
