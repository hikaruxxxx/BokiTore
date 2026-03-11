import Foundation

// MARK: - パターンデータベースのデータモデル

/// パターンデータベース全体 — boki3_pattern_db.json をデコードする
struct PatternDatabase: Codable {
    let version: String
    let description: String
    let journalEntryCategories: [JournalEntryCategory]
    let question2Patterns: Question2Patterns?
    let question3Patterns: Question3Patterns?

    enum CodingKeys: String, CodingKey {
        case version, description
        case journalEntryCategories = "journal_entry_categories"
        case question2Patterns = "question_2_patterns"
        case question3Patterns = "question_3_patterns"
    }
}

/// 仕訳カテゴリ（19種類: 現金取引、商品売買、手形取引 etc.）
struct JournalEntryCategory: Codable, Identifiable {
    let id: String                  // "cash_transactions"
    let name: String                // "現金取引"
    let frequency: String           // "A", "B", "C"
    let patterns: [JournalPattern]  // 配下の出題パターン
}

/// 個別の仕訳パターン
struct JournalPattern: Codable, Identifiable {
    let id: String                  // "cash_001"
    let description: String         // "通貨代用証券の受け取り"
    let examples: [String]          // 具体的な取引例
    let keyAccounts: [String]       // 使用する勘定科目
    let trapPatterns: [String]?     // ひっかけポイント
    let difficultyRange: [Int]?     // 難易度の範囲 [1, 2]

    enum CodingKeys: String, CodingKey {
        case id, description, examples
        case keyAccounts = "key_accounts"
        case trapPatterns = "trap_patterns"
        case difficultyRange = "difficulty_range"
    }
}

/// 第2問の出題パターン
struct Question2Patterns: Codable {
    let accountEntry: [AccountEntryPattern]?
    let subledgerSelection: [SubledgerSelectionPattern]?
    let theoryFill: [TheoryFillPattern]?

    enum CodingKeys: String, CodingKey {
        case accountEntry = "account_entry"
        case subledgerSelection = "subledger_selection"
        case theoryFill = "theory_fill"
    }
}

/// 勘定記入パターン（第2問⑵-A）
struct AccountEntryPattern: Codable, Identifiable {
    let id: String
    let description: String
    let targetAccounts: [String]?

    enum CodingKeys: String, CodingKey {
        case id, description
        case targetAccounts = "target_accounts"
    }
}

/// 補助簿選択パターン（第2問⑵-A）
struct SubledgerSelectionPattern: Codable, Identifiable {
    let id: String
    let description: String
}

/// 理論穴埋めパターン（第2問⑵-B）
struct TheoryFillPattern: Codable, Identifiable {
    let id: String
    let description: String
    let topics: [String]?
}

/// 第3問の決算整理パターン
struct Question3Patterns: Codable {
    let adjustmentPatterns: [AdjustmentPattern]?

    enum CodingKeys: String, CodingKey {
        case adjustmentPatterns = "adjustment_patterns"
    }
}

/// 決算整理仕訳パターン
struct AdjustmentPattern: Codable, Identifiable {
    let id: String
    let description: String
    let keyAccounts: [String]?

    enum CodingKeys: String, CodingKey {
        case id, description
        case keyAccounts = "key_accounts"
    }
}

// MARK: - ローダー

/// パターンデータベースの読み込みと提供を行うシングルトン
/// - 出題パターンの参照（問題生成の品質向上用）
/// - カテゴリ別の出題頻度情報の提供
/// - ひっかけパターンの参照（解説の充実化用）
class PatternDBLoader {
    /// シングルトンインスタンス
    static let shared = PatternDBLoader()

    /// 読み込んだパターンデータベース
    private(set) var database: PatternDatabase?

    /// 初期化時にJSONを読み込む
    private init() {
        loadDatabase()
    }

    /// boki3_pattern_db.json を読み込む
    private func loadDatabase() {
        do {
            guard let url = Bundle.main.url(forResource: "boki3_pattern_db", withExtension: "json") else {
                #if DEBUG
                print("⚠️ boki3_pattern_db.json がバンドルに見つかりません")
                #endif
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            database = try decoder.decode(PatternDatabase.self, from: data)

            #if DEBUG
            let categoryCount = database?.journalEntryCategories.count ?? 0
            let patternCount = database?.journalEntryCategories.reduce(0) { $0 + $1.patterns.count } ?? 0
            print("✅ パターンDB読み込み完了: \(categoryCount)カテゴリ, \(patternCount)パターン")
            #endif
        } catch {
            #if DEBUG
            print("❌ パターンDB読み込みエラー: \(error)")
            #endif
        }
    }

    // MARK: - 公開API

    /// 全仕訳カテゴリを取得
    var journalCategories: [JournalEntryCategory] {
        database?.journalEntryCategories ?? []
    }

    /// 出題頻度Aのカテゴリのみ取得（最重要の出題範囲）
    var frequencyACategories: [JournalEntryCategory] {
        journalCategories.filter { $0.frequency == "A" }
    }

    /// 指定カテゴリIDのパターンを取得
    func patterns(for categoryId: String) -> [JournalPattern] {
        journalCategories.first { $0.id == categoryId }?.patterns ?? []
    }

    /// 指定パターンIDのひっかけポイントを取得（解説の補足に使用）
    func trapPatterns(for patternId: String) -> [String] {
        for category in journalCategories {
            if let pattern = category.patterns.first(where: { $0.id == patternId }) {
                return pattern.trapPatterns ?? []
            }
        }
        return []
    }

    /// 全パターン数を取得
    var totalPatternCount: Int {
        journalCategories.reduce(0) { $0 + $1.patterns.count }
    }

    /// カテゴリ名からIDを引く（問題データとの紐付け用）
    func categoryId(for name: String) -> String? {
        journalCategories.first { $0.name == name }?.id
    }
}
