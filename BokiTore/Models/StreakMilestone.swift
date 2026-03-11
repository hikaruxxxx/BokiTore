import Foundation
import SwiftData

/// ストリークマイルストーン達成記録
/// 7/30/100/365日の連続学習達成時に作成される
@Model
class StreakMilestone {
    /// マイルストーン日数（7, 30, 100, 365）
    var days: Int
    /// ランク名（Bronze, Silver, Gold, Master）
    var rank: String
    /// 達成日時
    var achievedAt: Date

    init(days: Int, rank: String, achievedAt: Date = .now) {
        self.days = days
        self.rank = rank
        self.achievedAt = achievedAt
    }
}
