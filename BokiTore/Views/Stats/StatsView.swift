import SwiftUI
import SwiftData

/// 統計画面 — 学習進捗の表示
struct StatsView: View {
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \UserProgress.answeredAt, order: .reverse) private var allProgress: [UserProgress]
    /// 今日の解答履歴（日付フィルタ済み — 全件ロードを回避）
    @Query private var todayProgress: [UserProgress]
    @Query(sort: \StudyStreak.date, order: .reverse) private var streaks: [StudyStreak]

    init() {
        // 今日の解答をSQLレベルでフィルタ（allProgressの再フィルタを回避）
        let today = Calendar.current.startOfDay(for: .now)
        _todayProgress = Query(
            filter: #Predicate<UserProgress> { $0.answeredAt >= today }
        )
    }

    /// 総解答数
    private var totalAnswered: Int { allProgress.count }

    /// 全体の正答率
    private var overallAccuracy: Int {
        guard !allProgress.isEmpty else { return 0 }
        let correct = allProgress.filter { $0.isCorrect }.count
        return Int(Double(correct) / Double(allProgress.count) * 100)
    }

    /// 学習日数
    private var studyDays: Int { streaks.count }

    /// 連続学習日数（共通ロジック使用）
    private var consecutiveDays: Int {
        streaks.consecutiveDays()
    }

    /// 今日の解答数（フィルタ済みQueryから取得）
    private var todayAnswered: Int {
        todayProgress.count
    }

    /// 今日の正答率（フィルタ済みQueryから取得）
    private var todayAccuracy: Int {
        guard !todayProgress.isEmpty else { return 0 }
        let correct = todayProgress.filter { $0.isCorrect }.count
        return Int(Double(correct) / Double(todayProgress.count) * 100)
    }

    /// 平均回答時間
    private var averageTime: String {
        guard !allProgress.isEmpty else { return "0秒" }
        let total = allProgress.reduce(0.0) { $0 + $1.timeSpent }
        let avg = Int(total / Double(allProgress.count))
        if avg >= 60 {
            return "\(avg / 60)分\(avg % 60)秒"
        }
        return "\(avg)秒"
    }

    var body: some View {
        NavigationStack {
            if allProgress.isEmpty {
                // 初回起動時の空状態
                ContentUnavailableView(
                    "まだ学習データがありません",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text("問題を解くと、ここに学習統計が表示されます。")
                )
                .navigationTitle("学習統計")
            } else {
            List {
                // 今日の学習
                Section("今日の学習") {
                    StatRow(label: "解答数", value: "\(todayAnswered)問", icon: "pencil.circle.fill", color: .appPrimary)
                    StatRow(label: "正答率", value: "\(todayAccuracy)%", icon: "checkmark.circle.fill", color: todayAccuracy >= 80 ? .appSecondary : .orange)
                }

                // 累計統計
                Section("累計") {
                    StatRow(label: "総解答数", value: "\(totalAnswered)問", icon: "number.circle.fill", color: .appPrimary)
                    StatRow(label: "正答率", value: "\(overallAccuracy)%", icon: "chart.pie.fill", color: overallAccuracy >= 80 ? .appSecondary : .orange)
                    StatRow(label: "平均回答時間", value: averageTime, icon: "timer", color: .purple)
                    StatRow(label: "学習日数", value: "\(studyDays)日", icon: "calendar", color: .appPrimary)
                    StatRow(label: "連続学習", value: "\(consecutiveDays)日", icon: "flame.fill", color: .orange)
                }

                // ストリークマイルストーン
                Section {
                    StreakMilestoneSection(consecutiveDays: consecutiveDays)
                }

                // 直近7日間のアクティビティ
                Section("直近7日間") {
                    WeeklyActivityView(streaks: streaks)
                }

                // カテゴリ別マスタリー
                Section("カテゴリ別マスタリー") {
                    MasteryBadgesView(allProgress: allProgress)
                }

                // カテゴリ別正答率
                Section("カテゴリ別正答率") {
                    ForEach(JournalEntrySubcategory.allCases) { subcategory in
                        let accuracy = categoryAccuracy(for: subcategory)
                        CategoryAccuracyRow(
                            name: subcategory.displayName,
                            accuracy: accuracy
                        )
                    }
                }

                // 苦手な問題（正答率が低いもの）
                let weakQuestions = findWeakQuestions()
                if !weakQuestions.isEmpty {
                    Section("苦手な問題") {
                        ForEach(weakQuestions, id: \.question.id) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.question.questionText)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    Text("正答率: \(item.accuracy)%（\(item.attempts)回解答）")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                CircularProgressView(progress: Double(item.accuracy) / 100.0)
                                    .frame(width: 36, height: 36)
                            }
                        }

                        // 苦手問題を復習
                        NavigationLink {
                            QuizView(questions: weakQuestions.map { $0.question })
                        } label: {
                            Label("苦手問題を復習", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
            }
            .navigationTitle("学習統計")
            .safeAreaInset(edge: .bottom) {
                if !storeManager.isPremium {
                    AdBannerPlaceholder()
                }
            }
            } // else (データがある場合)
        }
    }

    /// 指定カテゴリの正答率を計算
    private func categoryAccuracy(for subcategory: JournalEntrySubcategory) -> Int {
        let questions = QuestionLoader.shared.questions(forSubcategory: subcategory.rawValue)
        let questionIds = Set(questions.map { $0.id })
        let categoryProgress = allProgress.filter { questionIds.contains($0.questionId) }
        guard !categoryProgress.isEmpty else { return 0 }
        let correct = categoryProgress.filter { $0.isCorrect }.count
        return Int(Double(correct) / Double(categoryProgress.count) * 100)
    }

    /// 苦手な問題を特定（正答率50%以下で2回以上解答した問題）
    private func findWeakQuestions() -> [(question: Question, accuracy: Int, attempts: Int)] {
        // 問題IDごとに解答履歴をグループ化
        var questionStats: [String: (correct: Int, total: Int)] = [:]
        for progress in allProgress {
            var stat = questionStats[progress.questionId] ?? (correct: 0, total: 0)
            stat.total += 1
            if progress.isCorrect { stat.correct += 1 }
            questionStats[progress.questionId] = stat
        }

        // 正答率が低い問題を抽出
        let weakIds = questionStats
            .filter { $0.value.total >= 2 } // 2回以上解答
            .filter { Double($0.value.correct) / Double($0.value.total) < 0.5 } // 正答率50%未満
            .sorted { Double($0.value.correct) / Double($0.value.total) < Double($1.value.correct) / Double($1.value.total) }
            .prefix(5) // 上位5問

        return weakIds.compactMap { id, stat in
            guard let question = QuestionLoader.shared.allQuestions.first(where: { $0.id == id }) else { return nil }
            let accuracy = Int(Double(stat.correct) / Double(stat.total) * 100)
            return (question: question, accuracy: accuracy, attempts: stat.total)
        }
    }
}

#Preview {
    StatsView()
        .environment(StoreManager.shared)
        .modelContainer(.preview)
}
