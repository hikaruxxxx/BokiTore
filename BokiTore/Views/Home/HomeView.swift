import SwiftUI
import SwiftData

/// ホーム画面 — メインメニュー + ゲーミフィケーション情報
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    /// 全解答履歴（正答率計算用 — 将来的にキャッシュ統計に置き換え予定）
    @Query private var allProgress: [UserProgress]
    /// 今日の解答履歴（日付フィルタ済み — 全件ロードを回避）
    @Query private var todayProgress: [UserProgress]
    @Query(sort: \StudyStreak.date, order: .reverse) private var streaks: [StudyStreak]
    @Query private var studyPlans: [StudyPlan]
    /// 今日のデイリーミッション（日付フィルタ済み — 全件ロードを回避）
    @Query private var todayMissions: [DailyMission]
    /// 今日期限の復習問題（日付フィルタ済み — 全件ロードを回避）
    @Query private var reviewsDueToday: [ReviewItem]
    @Query(sort: \TimeAttackRecord.correctCount, order: .reverse) private var timeAttackRecords: [TimeAttackRecord]

    init() {
        // 日付ベースのQueryに#Predicateフィルタを設定
        // （SwiftDataがSQLレベルでフィルタ → メモリ使用量を大幅削減）
        let today = Calendar.current.startOfDay(for: .now)
        _todayProgress = Query(
            filter: #Predicate<UserProgress> { $0.answeredAt >= today }
        )
        _todayMissions = Query(
            filter: #Predicate<DailyMission> { $0.date == today },
            sort: \.orderIndex
        )
        _reviewsDueToday = Query(
            filter: #Predicate<ReviewItem> { $0.nextReviewDate <= today }
        )
    }

    /// 全体の正答率を計算
    private var overallAccuracy: Int {
        guard !allProgress.isEmpty else { return 0 }
        let correct = allProgress.filter { $0.isCorrect }.count
        return Int(Double(correct) / Double(allProgress.count) * 100)
    }

    /// 総問題数（QuestionLoaderから取得）
    private var totalQuestionCount: Int {
        QuestionLoader.shared.allQuestions.count
    }

    /// 今日の解答数（フィルタ済みQueryから取得）
    private var todayAnswered: Int {
        todayProgress.count
    }

    /// 学習計画（1つだけ存在する想定）
    private var studyPlan: StudyPlan? {
        studyPlans.first { $0.isOnboardingCompleted }
    }

    /// タイムアタックのパーソナルベスト
    private var timeAttackBest: Int {
        timeAttackRecords.first?.correctCount ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // アプリタイトル
                    Text("簿記トレ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 8)

                    // 学習計画プログレス（設定済みの場合）
                    if let plan = studyPlan {
                        StudyPlanProgressView(
                            todayAnswered: todayAnswered,
                            dailyGoal: plan.dailyGoal,
                            examDate: plan.examDate
                        )
                    }

                    // デイリーチャレンジ（ミッションがある場合）
                    if !todayMissions.isEmpty {
                        DailyChallengeSection(missions: todayMissions)
                    }

                    // 復習バナー（復習問題がある場合）
                    if !reviewsDueToday.isEmpty {
                        let questionIds = reviewsDueToday.map { $0.questionId }
                        let questions = QuestionLoader.shared.questions(byIds: questionIds)
                        if !questions.isEmpty {
                            ReviewBannerView(count: questions.count, questions: questions)
                        }
                    }

                    // メインボタン: 問題を解く（試験セクション選択へ）
                    NavigationLink {
                        ExamSectionView()
                    } label: {
                        HomeMenuCard(
                            icon: "pencil.and.list.clipboard",
                            title: "問題を解く",
                            subtitle: "\(totalQuestionCount)問",
                            color: .appPrimary
                        )
                    }

                    // タイムアタック
                    NavigationLink {
                        TimeAttackView()
                    } label: {
                        HomeMenuCard(
                            icon: "timer",
                            title: "タイムアタック",
                            subtitle: timeAttackBest > 0 ? "ベスト: \(timeAttackBest)問正解" : "60秒チャレンジ",
                            color: .orange
                        )
                    }

                    // ブックマーク
                    NavigationLink {
                        BookmarkListView()
                    } label: {
                        HomeMenuCard(
                            icon: "bookmark.fill",
                            title: "ブックマーク",
                            subtitle: "保存した問題",
                            color: .purple
                        )
                    }

                    // 実力診断
                    NavigationLink {
                        DiagnosisFlowView()
                    } label: {
                        HomeMenuCard(
                            icon: "stethoscope",
                            title: "実力診断",
                            subtitle: "弱点を分析",
                            color: Color.appError
                        )
                    }

                    // 学習ロードマップ
                    NavigationLink {
                        RoadmapView()
                    } label: {
                        HomeMenuCard(
                            icon: "map.fill",
                            title: "学習ロードマップ",
                            subtitle: "弱点克服プラン",
                            color: .indigo
                        )
                    }

                    // 学習統計ボタン
                    NavigationLink {
                        StatsView()
                    } label: {
                        HomeMenuCard(
                            icon: "chart.bar.fill",
                            title: "学習統計",
                            subtitle: "正答率 \(overallAccuracy)%",
                            color: .appSecondary
                        )
                    }

                    // クロスプロモーションバナー（ターゲティング付き）
                    CrossPromoBannerView(
                        placement: "home",
                        userCerts: studyPlan?.getInterestedCerts() ?? [],
                        userPurpose: studyPlan?.studyPurpose ?? ""
                    )
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                if !storeManager.isPremium {
                    AdBannerPlaceholder()
                }
            }
            .onAppear {
                // デイリーチャレンジの生成チェック
                DailyChallengeManager.shared.ensureTodaysMissions(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(StoreManager.shared)
        .modelContainer(.preview)
}
