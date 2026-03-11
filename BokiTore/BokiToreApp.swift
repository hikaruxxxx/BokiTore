import SwiftUI
import SwiftData
import AppTrackingTransparency

/// アプリのエントリポイント
@main
struct BokiToreApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    init() {
        // Firebase Analyticsを初期化（AdMobより先に行う必要がある）
        AnalyticsManager.configure()
        // レビュー依頼の初回起動日を記録
        ReviewManager.registerFirstLaunchIfNeeded()

        // デバッグ用: -resetData 起動引数で全SwiftDataを初期化
        #if DEBUG
        if CommandLine.arguments.contains("-resetData") {
            Self.deleteSwiftDataStore()
            // AppStorageもリセット（オンボーディング状態など）
            let domain = Bundle.main.bundleIdentifier ?? ""
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("🔄 デバッグ: 全データをリセットしました")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                // StoreManagerをEnvironment経由で全Viewに提供する
                .environment(StoreManager.shared)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // AdMob SDKを初期化
                    AdManager.shared.configure()
                }
                .task {
                    // ATT（App Tracking Transparency）許可リクエスト
                    // 少し遅延させてからダイアログを表示（UI表示後に行う必要がある）
                    try? await Task.sleep(for: .seconds(1))
                    await requestTrackingPermission()
                }
        }
        // Swift Dataのモデルコンテナを設定（全モデルを登録）
        .modelContainer(for: [
            UserProgress.self,
            StudyStreak.self,
            DailyMission.self,
            DailyChallengeBadge.self,
            ReviewItem.self,
            TimeAttackRecord.self,
            StudyPlan.self,
            StreakMilestone.self,
            // v2.2 将来機能の基盤モデル
            Bookmark.self,
            DiagnosisResult.self,
            StudyRoadmap.self
        ])
    }

    /// ATT許可をリクエストする
    @MainActor
    private func requestTrackingPermission() async {
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    /// SwiftDataのストアファイルを削除する（デバッグ用）
    #if DEBUG
    private static func deleteSwiftDataStore() {
        let url = URL.applicationSupportDirectory
            .appending(path: "default.store")
        let fileManager = FileManager.default
        // default.store 本体 + WAL/SHM ファイルも削除
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: url.path() + suffix)
            if fileManager.fileExists(atPath: fileURL.path()) {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    print("⚠️ デバッグ: ストア削除エラー: \(error)")
                }
            }
        }
    }
    #endif
}

/// アプリのルートビュー（オンボーディング表示制御 + スマート通知管理）
struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var studyPlans: [StudyPlan]
    @Query(sort: \StudyStreak.date, order: .reverse) private var streaks: [StudyStreak]
    @Query(sort: \StreakMilestone.days) private var achievedMilestones: [StreakMilestone]
    @State private var showOnboarding = false
    /// デバッグリセット済みフラグ（二重実行防止）
    @State private var hasPerformedDebugReset = false
    /// マイルストーン達成お祝い表示
    @State private var showMilestoneCelebration = false
    @State private var milestoneTitle = ""
    @State private var milestoneSubtitle = ""
    /// マイルストーンチェックを1日1回に制限
    @AppStorage("lastMilestoneCheckDate") private var lastMilestoneCheckDate = ""

    /// オンボーディング済みかどうか
    private var needsOnboarding: Bool {
        !studyPlans.contains { $0.isOnboardingCompleted }
    }

    var body: some View {
        ZStack {
            ContentView()
                .onAppear {
                    // デバッグ用: modelContext経由で全データを確実に削除
                    #if DEBUG
                    if CommandLine.arguments.contains("-resetData") && !hasPerformedDebugReset {
                        hasPerformedDebugReset = true
                        deleteAllRecords()
                        // @Queryの更新を待たず、直接オンボーディングを強制表示
                        showOnboarding = true
                        return
                    }
                    #endif

                    // 初回起動時にオンボーディングを表示
                    if needsOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    StudyPlanOnboardingView()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // フォアグラウンド復帰時にスマート通知を再スケジュール
                        SmartReminderManager.shared.rescheduleSmartNotifications(
                            modelContext: modelContext
                        )
                        // ストリークマイルストーンチェック（1日1回）
                        checkStreakMilestones()
                        // Firebase User Propertiesを更新
                        updateAnalyticsUserProperties()
                    }
                }

            // マイルストーン達成お祝い
            if showMilestoneCelebration {
                CelebrationOverlay(
                    isShowing: $showMilestoneCelebration,
                    title: milestoneTitle,
                    subtitle: milestoneSubtitle
                )
            }
        }
    }

    // MARK: - デバッグ用データリセット

    #if DEBUG
    /// modelContext経由で全レコードを削除する（確実なリセット）
    private func deleteAllRecords() {
        do {
            try modelContext.delete(model: StudyPlan.self)
            try modelContext.delete(model: UserProgress.self)
            try modelContext.delete(model: StudyStreak.self)
            try modelContext.delete(model: DailyMission.self)
            try modelContext.delete(model: DailyChallengeBadge.self)
            try modelContext.delete(model: ReviewItem.self)
            try modelContext.delete(model: TimeAttackRecord.self)
            try modelContext.delete(model: StreakMilestone.self)
            // v2.2 将来機能の基盤モデル
            try modelContext.delete(model: Bookmark.self)
            try modelContext.delete(model: DiagnosisResult.self)
            try modelContext.delete(model: StudyRoadmap.self)
            try modelContext.save()
            print("🔄 デバッグ: modelContext経由で全レコードを削除しました")
        } catch {
            print("⚠️ デバッグ: レコード削除エラー: \(error)")
        }
    }
    #endif

    // MARK: - ストリークマイルストーンチェック

    /// 連続学習日数を計算してマイルストーン達成を確認する
    private func checkStreakMilestones() {
        // 1日1回の制限チェック
        let todayString = formatDate(Date.now)
        guard lastMilestoneCheckDate != todayString else { return }
        lastMilestoneCheckDate = todayString

        // 連続学習日数を計算
        let consecutive = calculateConsecutiveDays()
        guard consecutive > 0 else { return }

        // 達成済みの日数セット
        let achievedDays = Set(achievedMilestones.map { $0.days })

        // 新規達成マイルストーンを確認
        for milestone in Constants.Gamification.streakMilestones {
            if consecutive >= milestone.days && !achievedDays.contains(milestone.days) {
                // 新規達成をSwiftDataに保存
                let record = StreakMilestone(
                    days: milestone.days,
                    rank: milestone.rank
                )
                modelContext.insert(record)

                // Analyticsにレベルアップイベントを送信
                AnalyticsManager.logLevelUp(days: milestone.days, rank: milestone.rank)

                // お祝い表示（最も大きい達成分のみ表示）
                milestoneTitle = "\(milestone.days)日達成!"
                milestoneSubtitle = "\(milestone.rank) ストリーク"
                showMilestoneCelebration = true
            }
        }
    }

    /// 連続学習日数を計算する（共通ロジック使用）
    private func calculateConsecutiveDays() -> Int {
        streaks.consecutiveDays()
    }

    /// 日付を文字列に変換（日次制限用・キャッシュ済みFormatter使用）
    private func formatDate(_ date: Date) -> String {
        DateFormatter.isoDate.string(from: date)
    }

    // MARK: - Analytics User Properties

    /// Firebase AnalyticsのUser Propertiesを更新する
    private func updateAnalyticsUserProperties() {
        let consecutive = calculateConsecutiveDays()
        let plan = studyPlans.first(where: { $0.isOnboardingCompleted })
        let examDateString: String? = plan?.examDate.map { DateFormatter.isoDate.string(from: $0) }
        // 学習目的（空文字列はnilに変換）
        let purpose = (plan?.studyPurpose.isEmpty == false) ? plan?.studyPurpose : nil
        // 興味資格（カンマ区切り文字列に変換）
        let certs = plan?.getInterestedCerts()
        let certsString = (certs?.isEmpty == false) ? certs?.joined(separator: ",") : nil
        // fetchCountでSQLレベルのCOUNT(*)を実行（全レコードのメモリロードを回避）
        let totalAnswered = (try? modelContext.fetchCount(FetchDescriptor<UserProgress>())) ?? 0
        AnalyticsManager.updateUserProperties(
            examDate: examDateString,
            streakDays: consecutive,
            totalAnswered: totalAnswered,
            studyPurpose: purpose,
            interestedCerts: certsString
        )
    }
}
