import Foundation

/// 出題フォーマットの種類
enum QuestionFormat: String, Codable {
    /// 従来の4択仕訳問題
    case multipleChoice = "multiple_choice"
    /// CBT仕訳入力（勘定科目候補から選択+金額入力）
    case cbtJournalEntry = "cbt_journal_entry"
    /// T勘定空欄補充（T字勘定の空欄を埋める）
    case tAccountFill = "t_account_fill"
    /// 補助簿選択（取引ごとに該当する補助簿をチェック）
    case subledgerSelect = "subledger_select"
    /// 理論穴埋め（文章中の空欄にプルダウンから語句選択）
    case theoryFill = "theory_fill"
}

/// 問題データモデル（JSONからデコードする）
struct Question: Codable, Identifiable {
    let id: String              // "q001"
    let category: String        // "journalEntry"
    let subcategory: String     // "sales"
    let difficulty: Int         // 1-3
    let questionType: String    // "multipleChoice"
    let questionText: String    // 問題文
    let choices: [Choice]       // 選択肢（multipleChoice用、他フォーマットでは空配列）
    let correctAnswer: String   // "a"（multipleChoice用、他フォーマットでは空文字）
    let explanation: String     // 解説
    let tags: [String]          // タグ

    // MARK: - v2.2 拡張フィールド（後方互換: 既存JSONでは省略可能）

    /// 用語解説リスト — 問題に登場する専門用語を初心者向けに説明
    let termDefinitions: [TermDefinition]?

    /// 出題頻度ランク: "A"（毎回出る）, "B"（よく出る）, "C"（たまに出る）
    let frequencyRank: String?

    /// 出題セクション: "第1問", "第2問⑴", "第2問⑵-A", "第2問⑵-B"
    let examSection: String?

    // MARK: - v2.3 複数フォーマット対応（後方互換: 既存JSONでは省略可能）

    /// 出題フォーマット（nil = multipleChoice として扱う — 後方互換）
    let format: QuestionFormat?

    /// フォーマット別の問題データ（nil = 従来のchoices方式）
    let questionData: QuestionData?

    /// 実効フォーマット（後方互換: nilならmultipleChoice）
    var effectiveFormat: QuestionFormat {
        format ?? .multipleChoice
    }
}

/// 用語解説データモデル — 問題の解説画面で表示する簿記用語の説明
struct TermDefinition: Codable {
    /// 用語名（例: "売掛金"）
    let term: String
    /// 分類（例: "資産", "費用", "収益"）
    let category: String
    /// 用語の定義（初心者向けの説明）
    let definition: String
    /// 身近な例え（実生活での具体例）
    let realWorldExample: String?
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
