import Foundation
import SwiftData

/// クイズ画面のビューモデル — 問題の進行と解答の管理
@Observable
class QuizViewModel {
    /// 学習セッション（問題リストと解答結果を保持）
    var session: StudySession
    /// 選択中の解答
    var selectedAnswer: String?
    /// 解答結果を表示中かどうか
    var showResult = false
    /// 問題の開始時刻（所要時間を計測するため）
    private var questionStartTime: Date = .now
    /// 経過時間（タイマー表示用）
    var elapsedTime: TimeInterval = 0
    /// タイマー用のTimerインスタンス
    private var timer: Timer?

    /// 指定された問題リストでViewModelを初期化
    init(questions: [Question]) {
        self.session = StudySession(questions: questions.shuffled())
        startTimer()
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

    /// 現在の解答が正解か
    var isCurrentAnswerCorrect: Bool {
        guard let question = currentQuestion, let answer = selectedAnswer else { return false }
        return answer == question.correctAnswer
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

    /// 選択肢を選択して解答する
    func selectAnswer(_ answerId: String) {
        guard !showResult, let question = currentQuestion else { return }

        selectedAnswer = answerId
        showResult = true

        // タイマーを停止
        timer?.invalidate()

        // 所要時間を記録
        let timeSpent = Date.now.timeIntervalSince(questionStartTime)
        session.timesSpent[question.id] = timeSpent

        // 正解/不正解を記録
        let isCorrect = answerId == question.correctAnswer
        session.answers[question.id] = isCorrect

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
        selectedAnswer = nil
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
}
