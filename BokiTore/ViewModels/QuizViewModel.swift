import Foundation
import SwiftData

/// クイズ画面のビューモデル — 問題の進行と解答の管理
@Observable
class QuizViewModel {
    /// 学習セッション（問題リストと解答結果を保持）
    var session: StudySession
    /// 現在のユーザー解答（フォーマット別）
    var currentAnswer: UserAnswer?

    /// multipleChoiceの選択ID（後方互換: ChoiceButton表示判定用）
    var selectedAnswerId: String? {
        currentAnswer?.multipleChoiceId
    }
    /// 解答結果を表示中かどうか
    var showResult = false
    /// 問題の開始時刻（所要時間を計測するため）
    private var questionStartTime: Date = .now
    /// 経過時間（タイマー表示用）
    var elapsedTime: TimeInterval = 0
    /// タイマー用のTimerインスタンス
    private var timer: Timer?
    /// 連続正解カウンター（デイリーチャレンジ用・コンボ表示用）
    private(set) var consecutiveCorrectRun: Int = 0
    /// 問題ごとのシャッフル済み選択肢（正解が常に同じ位置にならないように）
    private var shuffledChoicesMap: [String: [Choice]] = [:]

    /// 指定された問題リストでViewModelを初期化
    init(questions: [Question]) {
        let shuffled = questions.shuffled()
        self.session = StudySession(questions: shuffled)
        // 各問題の選択肢をシャッフルして保持（問題中に順番が変わらないように）
        for question in shuffled {
            shuffledChoicesMap[question.id] = question.choices.shuffled()
        }
        startTimer()
    }

    /// 現在の問題のシャッフル済み選択肢を返す
    func shuffledChoices(for question: Question) -> [Choice] {
        shuffledChoicesMap[question.id] ?? question.choices
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - タイマー

    /// タイマーを開始する
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedTime = Date.now.timeIntervalSince(self.questionStartTime)
        }
    }

    /// 現在の問題の経過時間をフォーマットして返す
    var formattedElapsedTime: String {
        let seconds = Int(elapsedTime)
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - 計算プロパティ

    /// 現在の問題
    var currentQuestion: Question? { session.currentQuestion }

    /// 現在の問題インデックス
    var currentIndex: Int { session.currentIndex }

    /// 全問題数
    var totalCount: Int { session.questions.count }

    /// 進捗（0.0〜1.0）
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    /// 全問解答済みか
    var isCompleted: Bool { session.isCompleted }

    /// 最後の問題か
    var isLastQuestion: Bool { currentIndex >= totalCount - 1 }

    /// 現在の解答が正解か（AnswerCheckerに委譲）
    var isCurrentAnswerCorrect: Bool {
        guard let question = currentQuestion, let answer = currentAnswer else { return false }
        return AnswerChecker.check(question: question, answer: answer)
    }

    /// 間違えた問題のリスト
    var incorrectQuestions: [Question] {
        let ids = session.incorrectQuestionIds
        return session.questions.filter { ids.contains($0.id) }
    }

    /// 合計所要時間のフォーマット表示
    var formattedTotalTime: String {
        let total = Int(session.totalTimeSpent)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }

    /// 現在の正答数（リアルタイム表示用）
    var currentCorrectCount: Int {
        session.answers.values.filter { $0 }.count
    }

    /// 現在までの正答率（リアルタイム表示用）
    var currentAccuracy: Int {
        guard !session.answers.isEmpty else { return 0 }
        return Int(Double(currentCorrectCount) / Double(session.answers.count) * 100)
    }

    // MARK: - アクション

    /// 解答を提出する（全フォーマット共通のエントリポイント）
    func submitAnswer(_ answer: UserAnswer) {
        guard !showResult, let question = currentQuestion else { return }

        currentAnswer = answer
        showResult = true

        // タイマーを停止
        timer?.invalidate()

        // 所要時間を記録
        let timeSpent = Date.now.timeIntervalSince(questionStartTime)
        session.timesSpent[question.id] = timeSpent

        // 正解/不正解を記録（AnswerCheckerに委譲）
        let isCorrect = AnswerChecker.check(question: question, answer: answer)
        session.answers[question.id] = isCorrect

        // 連続正解カウンターを更新
        if isCorrect {
            consecutiveCorrectRun += 1
            // コンボマイルストーンで追加フィードバック（3の倍数）
            if consecutiveCorrectRun >= 3 && consecutiveCorrectRun.isMultiple(of: 3) {
                FeedbackManager.combo()
            }
        } else {
            consecutiveCorrectRun = 0
        }

        // 触覚・サウンドフィードバック
        if isCorrect {
            FeedbackManager.correct()
        } else {
            FeedbackManager.incorrect()
        }

        // Firebase Analyticsに問題回答イベントを送信
        AnalyticsManager.logQuestionAnswered(
            questionId: question.id,
            category: question.category,
            subcategory: question.subcategory,
            isCorrect: isCorrect,
            timeSpentSec: timeSpent
        )

        // 広告マネージャーに解答数を通知
        AdManager.shared.incrementAnswerCount()
    }

    /// 次の問題に進む（解答結果をSwift Dataに保存）
    func nextQuestion(modelContext: ModelContext) {
        guard let question = currentQuestion else { return }

        let isCorrect = session.answers[question.id] ?? false
        let timeSpent = session.timesSpent[question.id] ?? 0

        // 先に次の問題へ進む（データ保存が失敗してもクイズは継続できるように）
        session.currentIndex += 1
        currentAnswer = nil
        showResult = false
        questionStartTime = .now
        elapsedTime = 0

        // タイマーを再開（まだ問題が残っている場合）
        if !session.isCompleted {
            startTimer()
        }

        // Swift Dataに解答履歴を保存
        let progress = UserProgress(
            questionId: question.id,
            isCorrect: isCorrect,
            timeSpent: timeSpent
        )
        modelContext.insert(progress)

        // 連続学習記録を更新
        updateStudyStreak(modelContext: modelContext, isCorrect: isCorrect)

        // デイリーチャレンジの進捗を更新
        DailyChallengeManager.shared.updateMissionProgress(
            modelContext: modelContext,
            question: question,
            isCorrect: isCorrect,
            consecutiveCorrectRun: consecutiveCorrectRun
        )

        // 復習アイテムを更新（間隔反復学習）
        updateReviewItem(modelContext: modelContext, questionId: question.id, isCorrect: isCorrect)
    }

    /// 連続学習記録を更新する
    private func updateStudyStreak(modelContext: ModelContext, isCorrect: Bool) {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }

            // 今日のStreakを検索（Date範囲で検索してクラッシュを回避）
            let descriptor = FetchDescriptor<StudyStreak>(
                predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
            )

            let existing = try modelContext.fetch(descriptor)
            if let streak = existing.first {
                // 既存のStreakを更新
                streak.questionsAnswered += 1
                if isCorrect { streak.correctCount += 1 }
            } else {
                // 新しいStreakを作成
                let streak = StudyStreak(
                    date: today,
                    questionsAnswered: 1,
                    correctCount: isCorrect ? 1 : 0
                )
                modelContext.insert(streak)
            }
        } catch {
            #if DEBUG
            print("StudyStreak更新エラー: \(error)")
            #endif
        }
    }

    /// 復習アイテムを更新する（間隔反復学習）
    /// 不正解: ReviewItem作成/リセット → 翌日に復習
    /// 正解 & ReviewItem存在: 次のインターバルへ進む
    private func updateReviewItem(modelContext: ModelContext, questionId: String, isCorrect: Bool) {
        do {
            let descriptor = FetchDescriptor<ReviewItem>(
                predicate: #Predicate { $0.questionId == questionId }
            )
            let existing = try modelContext.fetch(descriptor)

            if isCorrect {
                // 正解: 既存のReviewItemがあればインターバルを進める
                if let item = existing.first {
                    item.intervalStep += 1
                    item.consecutiveCorrectCount += 1

                    let intervals = Constants.Gamification.reviewIntervals
                    if item.intervalStep >= intervals.count {
                        // マスター済み → 削除
                        modelContext.delete(item)
                    } else {
                        // 次の復習日を設定
                        let daysUntilNext = intervals[item.intervalStep]
                        item.nextReviewDate = Date.now.daysFromNow(daysUntilNext)
                    }
                }
                // ReviewItemがない正解問題は何もしない
            } else {
                // 不正解: ReviewItemを作成またはリセット
                if let item = existing.first {
                    // リセット
                    item.intervalStep = 0
                    item.consecutiveCorrectCount = 0
                    item.lastIncorrectAt = .now
                    item.nextReviewDate = Date.now.tomorrow
                } else {
                    // 新規作成
                    let item = ReviewItem(
                        questionId: questionId,
                        nextReviewDate: Date.now.tomorrow
                    )
                    modelContext.insert(item)
                }
            }
        } catch {
            #if DEBUG
            print("ReviewItem更新エラー: \(error)")
            #endif
        }
    }
}
