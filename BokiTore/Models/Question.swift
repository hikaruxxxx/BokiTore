import Foundation

/// 問題データモデル（JSONからデコードする）
struct Question: Codable, Identifiable {
    let id: String              // "q001"
    let category: String        // "journalEntry"
    let subcategory: String     // "sales"
    let difficulty: Int         // 1-3
    let questionType: String    // "multipleChoice"
    let questionText: String    // 問題文
    let choices: [Choice]       // 選択肢
    let correctAnswer: String   // "a"
    let explanation: String     // 解説
    let tags: [String]          // タグ
}

/// 選択肢データモデル
struct Choice: Codable, Identifiable {
    let id: String      // "a", "b", "c", "d"
    let debit: String   // 借方（例: "売掛金 100,000"）
    let credit: String  // 貸方（例: "売上 100,000"）
}

/// 問題バンク全体のラッパー
struct QuestionBank: Codable {
    let version: String
    let questions: [Question]
}
