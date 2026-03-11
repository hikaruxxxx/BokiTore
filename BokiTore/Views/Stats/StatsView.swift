import SwiftUI
import SwiftData

/// 統計画面 — 学習進捗の表示
struct StatsView: View {
    @Query(sort: \UserProgress.answeredAt, order: .reverse) private var allProgress: [UserProgress]
    @Query(sort: \StudyStreak.date, order: .reverse) private var streaks: [StudyStreak]

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

    /// 連続学習日数
    private var consecutiveDays: Int {
        guard !streaks.isEmpty else { return 0 }
        var count = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: .now)

        for streak in streaks {
            let streakDate = calendar.startOfDay(for: streak.date)
            if streakDate == checkDate {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return count
    }

    /// 今日の解答数
    private var todayAnswered: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return allProgress.filter { $0.answeredAt >= today }.count
    }

    /// 今日の正答率
    private var todayAccuracy: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let todayProgress = allProgress.filter { $0.answeredAt >= today }
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

                // 直近7日間のアクティビティ
                Section("直近7日間") {
                    WeeklyActivityView(streaks: streaks)
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
                if !StoreManager.shared.isPremium {
                    AdBannerPlaceholder()
                }
            }
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

/// 週間アクティビティ表示（棒グラフ風）
struct WeeklyActivityView: View {
    let streaks: [StudyStreak]

    /// 直近7日間のデータ
    private var weekData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let count = streaks
                .first { calendar.startOfDay(for: $0.date) == date }?
                .questionsAnswered ?? 0
            return (date: date, count: count)
        }
    }

    /// 最大解答数（グラフのスケール用）
    private var maxCount: Int {
        max(weekData.map { $0.count }.max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(weekData, id: \.date) { data in
                VStack(spacing: 4) {
                    // 解答数ラベル
                    if data.count > 0 {
                        Text("\(data.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // バー
                    RoundedRectangle(cornerRadius: 4)
                        .fill(data.count > 0 ? Color.appPrimary : Color(.systemFill))
                        .frame(height: max(CGFloat(data.count) / CGFloat(maxCount) * 60, 4))

                    // 曜日ラベル
                    Text(data.date.shortWeekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

/// 円形プログレスビュー（苦手問題の正答率表示用）
struct CircularProgressView: View {
    let progress: Double

    /// 正答率に応じた色
    private var color: Color {
        if progress >= 0.8 { return .appSecondary }
        if progress >= 0.5 { return .orange }
        return .appError
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

/// 統計行（アイコン付き）
struct StatRow: View {
    let label: String
    let value: String
    var icon: String = ""
    var color: Color = .appPrimary

    var body: some View {
        HStack {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
            }
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

/// カテゴリ別正答率行（プログレスバー付き）
struct CategoryAccuracyRow: View {
    let name: String
    let accuracy: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(accuracy)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(accuracyColor)
            }
            ProgressView(value: Double(accuracy), total: 100)
                .tint(accuracyColor)
        }
    }

    /// 正答率に応じた色
    private var accuracyColor: Color {
        if accuracy >= 80 { return .appSecondary }
        if accuracy >= 60 { return .orange }
        return .appError
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [UserProgress.self, StudyStreak.self], inMemory: true)
}
