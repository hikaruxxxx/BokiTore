import Foundation
import SwiftData

/// タイムアタックの記録（Swift Data）
@Model
class TimeAttackRecord {
    /// 記録した日時
    var recordedAt: Date
    /// 解答した問題数
    var questionsAnswered: Int
    /// 正答数
    var correctCount: Int
    /// 制限時間（秒）
    var timeLimitSeconds: Int

    init(recordedAt: Date = .now, questionsAnswered: Int, correctCount: Int,
         timeLimitSeconds: Int = 60) {
        self.recordedAt = recordedAt
        self.questionsAnswered = questionsAnswered
        self.correctCount = correctCount
        self.timeLimitSeconds = timeLimitSeconds
    }
}
