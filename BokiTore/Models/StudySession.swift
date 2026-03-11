import Foundation

/// 1回のクイズセッションを管理する構造体（メモリ上のみ、永続化しない）
struct StudySession {
    /// セッションで出題する問題リスト
    let questions: [Question]
    /// 現在の問題インデックス
    var currentIndex: Int = 0
    /// ユーザーの解答結果（問題IDと正解/不正解）
    var answers: [String: Bool] = [:]
    /// 各問題の所要時間（問題IDと秒数）
    var timesSpent: [String: TimeInterval] = [:]
    /// セッション開始時刻
    let startedAt: Date = .now

    /// 現在の問題を取得
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    /// 全問解答済みかどうか
    var isCompleted: Bool {
        currentIndex >= questions.count
    }

    /// 正答数
    var correctCount: Int {
        answers.values.filter { $0 }.count
    }

    /// 正答率（0.0〜1.0）
    var accuracy: Double {
        guard !answers.isEmpty else { return 0 }
        return Double(correctCount) / Double(answers.count)
    }

    /// 総所要時間（秒）
    var totalTimeSpent: TimeInterval {
        timesSpent.values.reduce(0, +)
    }

    /// 間違えた問題のIDリスト
    var incorrectQuestionIds: [String] {
        answers.filter { !$0.value }.map { $0.key }
    }
}
