import Foundation
import SwiftData

/// ホーム画面のビューモデル（将来の拡張用）
@Observable
class HomeViewModel {
    /// お知らせメッセージ（将来的にリモート取得する想定）
    var announcement: String?

    /// 今日のおすすめカテゴリを取得（将来実装）
    var recommendedCategory: QuestionCategory {
        .journalEntry
    }
}
