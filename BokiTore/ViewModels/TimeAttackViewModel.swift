import Foundation
import SwiftData

/// タイムアタックモードのビューモデル
/// 60秒のカウントダウンで何問正解できるかチャレンジ
@Observable
class TimeAttackViewModel {
    /// 全問題プール（ランダム順）
    private var questions: [Question]
    /// 現在の問題インデックス
    var currentIndex: Int = 0
    /// 解答済みの問題数
    var answeredCount: Int = 0
    /// 正答数
    var correctCount: Int = 0
    /// 残り時間（秒）
    var remainingTime: Int
    /// タイマー
    private var timer: Timer?
    /// ゲーム終了したか
    var isFinished: Bool = false
    /// 選択中の解答
    var selectedAnswer: String?
    /// 正解/不正解のフラッシュ表示
    var showFlash: Bool = false
    /// 最後の解答が正解だったか
    var lastAnswerCorrect: Bool = false

    /// 制限時間
    private let timeLimit: Int

    /// 現在の問題
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    init(timeLimit: Int = Constants.Gamification.timeAttackDuration) {
        self.timeLimit = timeLimit
        self.remainingTime = timeLimit
        // タイムアタックは4択（multipleChoice）のみ対象
        self.questions = QuestionLoader.shared.questions(forFormat: .multipleChoice).shuffled()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - ゲーム制御

    /// ゲーム開始
    func start() {
        remainingTime = timeLimit
        isFinished = false
        currentIndex = 0
        answeredCount = 0
        correctCount = 0
        questions = QuestionLoader.shared.questions(forFormat: .multipleChoice).shuffled()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.finishGame()
            }
        }
    }

    /// 解答を選択（即座に次の問題へ）
    func selectAnswer(_ answerId: String) {
        guard !isFinished, let question = currentQuestion else { return }

        let isCorrect = answerId == question.correctAnswer
        answeredCount += 1
        if isCorrect { correctCount += 1 }

        // フラッシュ表示
        lastAnswerCorrect = isCorrect
        selectedAnswer = answerId
        showFlash = true

        // 短いディレイ後に次の問題へ（async/await使用）
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard let self, !self.isFinished else { return }
            self.showFlash = false
            self.selectedAnswer = nil
            self.currentIndex += 1

            // 問題が尽きたらシャッフルして最初から
            if self.currentIndex >= self.questions.count {
                self.questions = QuestionLoader.shared.questions(forFormat: .multipleChoice).shuffled()
                self.currentIndex = 0
            }
        }
    }

    /// ゲーム終了
    private func finishGame() {
        timer?.invalidate()
        timer = nil
        isFinished = true
    }

    /// 記録を保存する
    func saveRecord(modelContext: ModelContext) {
        let record = TimeAttackRecord(
            questionsAnswered: answeredCount,
            correctCount: correctCount,
            timeLimitSeconds: timeLimit
        )
        modelContext.insert(record)
    }

    /// フォーマットされた残り時間
    var formattedRemainingTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
