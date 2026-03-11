import Foundation
import SwiftData

/// ブックマーク — ユーザーが「後で復習したい」とマークした問題
/// 将来の「復習モード」「苦手克服セッション」で活用する
@Model
class Bookmark {
    /// ブックマークした問題のID（QuestionBank.jsonのid）
    var questionId: String
    /// ブックマークした日時
    var createdAt: Date
    /// ブックマーク時のメモ（任意: ユーザーが理由を残せる）
    var note: String?
    /// ブックマーク時に正解だったか（false = 不正解でブックマーク → 苦手問題）
    var wasCorrect: Bool
    /// 問題のカテゴリ（フィルタリング用にキャッシュ）
    var category: String

    init(
        questionId: String,
        createdAt: Date = .now,
        note: String? = nil,
        wasCorrect: Bool = false,
        category: String = ""
    ) {
        self.questionId = questionId
        self.createdAt = createdAt
        self.note = note
        self.wasCorrect = wasCorrect
        self.category = category
    }
}
