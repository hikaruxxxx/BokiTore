import Foundation
import SwiftData

/// 復習スケジュールアイテム（間隔反復学習用）
/// 間違えた問題を 1日→3日→7日 の間隔で復習する
@Model
class ReviewItem {
    /// 対象の問題ID
    var questionId: String
    /// 次回復習予定日（00:00:00に正規化）
    var nextReviewDate: Date
    /// 現在のインターバルステップ（0=1日後, 1=3日後, 2=7日後）
    /// 3以上でマスター済み（削除対象）
    var intervalStep: Int
    /// 間違えた最後の日時
    var lastIncorrectAt: Date
    /// 復習で連続正解した回数
    var consecutiveCorrectCount: Int

    init(questionId: String, nextReviewDate: Date, intervalStep: Int = 0,
         lastIncorrectAt: Date = .now, consecutiveCorrectCount: Int = 0) {
        self.questionId = questionId
        self.nextReviewDate = Calendar.current.startOfDay(for: nextReviewDate)
        self.intervalStep = intervalStep
        self.lastIncorrectAt = lastIncorrectAt
        self.consecutiveCorrectCount = consecutiveCorrectCount
    }
}
