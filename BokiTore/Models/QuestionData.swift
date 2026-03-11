import Foundation

// MARK: - フォーマット別の問題データ

/// フォーマット別の問題データ（JSONの "type" フィールドで識別してデコード）
enum QuestionData: Codable {
    /// CBT仕訳入力データ
    case journalEntry(JournalEntryData)
    /// T勘定空欄補充データ
    case tAccountFill(TAccountFillData)
    /// 補助簿選択データ
    case subledgerSelect(SubledgerSelectData)
    /// 理論穴埋めデータ
    case theoryFill(TheoryFillData)

    // MARK: - Codable（"type" フィールドで分岐デコード）

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "journalEntry":
            self = .journalEntry(try JournalEntryData(from: decoder))
        case "tAccountFill":
            self = .tAccountFill(try TAccountFillData(from: decoder))
        case "subledgerSelect":
            self = .subledgerSelect(try SubledgerSelectData(from: decoder))
        case "theoryFill":
            self = .theoryFill(try TheoryFillData(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "不明なquestionDataタイプ: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .journalEntry(let data):
            try data.encode(to: encoder)
        case .tAccountFill(let data):
            try data.encode(to: encoder)
        case .subledgerSelect(let data):
            try data.encode(to: encoder)
        case .theoryFill(let data):
            try data.encode(to: encoder)
        }
    }
}

// MARK: - CBT仕訳入力データ

/// CBT仕訳入力の問題データ
struct JournalEntryData: Codable {
    /// データタイプ識別子（= "journalEntry"）
    let type: String
    /// 勘定科目候補リスト（正解+ダミー = 6個程度）
    let accountCandidates: [String]
    /// 正解の仕訳行リスト
    let correctEntries: [JournalLine]
}

/// 仕訳の1行（借方/貸方）
struct JournalLine: Codable, Equatable {
    /// "debit"（借方）または "credit"（貸方）
    let side: String
    /// 勘定科目名
    let account: String
    /// 金額
    let amount: Int

    /// 比較用のキー文字列
    var comparisonKey: String {
        "\(side)_\(account)_\(amount)"
    }
}

// MARK: - T勘定空欄補充データ

/// T勘定空欄補充の問題データ
struct TAccountFillData: Codable {
    /// データタイプ識別子（= "tAccountFill"）
    let type: String
    /// 勘定科目名（T字勘定のタイトル）
    let accountName: String
    /// 事前記入済みエントリ（ヒント用）
    let prefilledEntries: [TAccountEntry]
    /// 空欄リスト（ユーザーが埋める箇所）
    let blanks: [TAccountBlank]
}

/// T勘定の1エントリ（事前記入済み）
struct TAccountEntry: Codable, Identifiable {
    /// 一意なID（side + description + amountから生成）
    var id: String { "\(side)_\(description)_\(amount)" }
    /// "debit"（借方）または "credit"（貸方）
    let side: String
    /// 摘要（例: "前期繰越"、"売上"）
    let description: String
    /// 金額
    let amount: Int
    /// 日付（例: "4/1"）— 表示用、省略可能
    let date: String?
}

/// T勘定の空欄1つ
struct TAccountBlank: Codable, Identifiable {
    /// 空欄ID（例: "blank_1"）
    let id: String
    /// "debit"（借方）または "credit"（貸方）
    let side: String
    /// 同サイド内の表示位置（0始まり）
    let position: Int
    /// 回答タイプ: "account"（勘定科目）/ "amount"（金額）/ "description"（摘要）
    let answerType: String
    /// 正解の文字列
    let correctAnswer: String
}

// MARK: - 補助簿選択データ

/// 補助簿選択の問題データ
struct SubledgerSelectData: Codable {
    /// データタイプ識別子（= "subledgerSelect"）
    let type: String
    /// 取引リスト（各取引に対して補助簿を選択）
    let transactions: [SubledgerTransaction]
    /// 補助簿の選択肢リスト
    let subledgerOptions: [String]
}

/// 補助簿選択の1取引
struct SubledgerTransaction: Codable, Identifiable {
    /// 取引ID（例: "tx_1"）
    let id: String
    /// 取引の説明文
    let description: String
    /// 正解の補助簿リスト
    let correctSubledgers: [String]
}

// MARK: - 理論穴埋めデータ

/// 理論穴埋めの問題データ
struct TheoryFillData: Codable {
    /// データタイプ識別子（= "theoryFill"）
    let type: String
    /// 穴埋め付きの文章（"[blank_1]" がプレースホルダ）
    let passage: String
    /// 空欄リスト
    let blanks: [TheoryBlank]
}

/// 理論穴埋めの空欄1つ
struct TheoryBlank: Codable, Identifiable {
    /// 空欄ID（例: "blank_1"）
    let id: String
    /// 選択肢リスト（正解+ダミー = 6〜8個）
    let options: [String]
    /// 正解の語句
    let correctAnswer: String
}
