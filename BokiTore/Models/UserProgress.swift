import Foundation
import SwiftData

/// ユーザーの解答履歴を保存するモデル（Swift Data）
@Model
class UserProgress {
    /// 解いた問題のID
    var questionId: String
    /// 正解したかどうか
    var isCorrect: Bool
    /// 解答した日時
    var answeredAt: Date
    /// 所要時間（秒）
    var timeSpent: TimeInterval

    init(questionId: String, isCorrect: Bool, answeredAt: Date = .now, timeSpent: TimeInterval = 0) {
        self.questionId = questionId
        self.isCorrect = isCorrect
        self.answeredAt = answeredAt
        self.timeSpent = timeSpent
    }
}

/// 連続学習記録を保存するモデル（Swift Data）
@Model
class StudyStreak {
    /// 学習した日（時刻は00:00:00に正規化）
    var date: Date
    /// その日の解答数
    var questionsAnswered: Int
    /// その日の正答数
    var correctCount: Int

    init(date: Date, questionsAnswered: Int = 0, correctCount: Int = 0) {
        // 日付を00:00:00に正規化（ストリーク計算のずれを防止）
        self.date = Calendar.current.startOfDay(for: date)
        self.questionsAnswered = questionsAnswered
        self.correctCount = correctCount
    }
}
