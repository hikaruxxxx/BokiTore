import Foundation
import SwiftData

/// デイリーチャレンジのミッション種別
enum DailyMissionType: String, Codable {
    /// X問解く
    case solveCount
    /// 特定カテゴリをX問解く
    case solveCategory
    /// X問連続正解する
    case consecutiveCorrect
}

/// デイリーチャレンジの1つのミッション（Swift Data）
@Model
class DailyMission {
    /// ミッションが属する日付（00:00:00に正規化）
    var date: Date
    /// ミッション種別（rawValueで保存）
    var missionTypeRaw: String
    /// ミッション説明文（例:「仕訳問題を5問解こう」）
    var descriptionText: String
    /// 達成条件の目標値
    var targetValue: Int
    /// 現在の進捗値
    var currentValue: Int
    /// フィルター条件（カテゴリ名、nilなら条件なし）
    var filterKey: String?
    /// 達成済みかどうか
    var isCompleted: Bool
    /// ミッションの順番（0, 1, 2）
    var orderIndex: Int

    init(date: Date, missionTypeRaw: String, descriptionText: String,
         targetValue: Int, currentValue: Int = 0, filterKey: String? = nil,
         isCompleted: Bool = false, orderIndex: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.missionTypeRaw = missionTypeRaw
        self.descriptionText = descriptionText
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.filterKey = filterKey
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
    }

    /// 型安全なミッション種別アクセサ
    var missionType: DailyMissionType {
        DailyMissionType(rawValue: missionTypeRaw) ?? .solveCount
    }
}

/// デイリーチャレンジ全達成バッジ（3ミッション完了時に付与）
@Model
class DailyChallengeBadge {
    /// 達成した日付（00:00:00に正規化）
    var date: Date
    /// 達成した日時
    var earnedAt: Date

    init(date: Date, earnedAt: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.earnedAt = earnedAt
    }
}
