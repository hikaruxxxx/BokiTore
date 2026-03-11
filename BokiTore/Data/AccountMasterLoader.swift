import Foundation

/// 勘定科目マスタデータモデル — account_master.json をデコードする
struct AccountMaster: Codable {
    let version: String
    let description: String
    let updatedAt: String
    let accounts: AccountCategories
    let dummyGenerationRules: DummyGenerationRules
    let subledgerMaster: SubledgerMaster
    let theoryTopics: TheoryTopics

    enum CodingKeys: String, CodingKey {
        case version, description, accounts
        case updatedAt = "updated_at"
        case dummyGenerationRules = "dummy_generation_rules"
        case subledgerMaster = "subledger_master"
        case theoryTopics = "theory_topics"
    }
}

/// 勘定科目を分類別に管理する
struct AccountCategories: Codable {
    let assets: [String]            // 資産
    let contraAssets: [String]      // 資産のマイナス（貸倒引当金等）
    let liabilities: [String]       // 負債
    let equity: [String]            // 純資産
    let revenue: [String]           // 収益
    let expenses: [String]          // 費用
    let temporary: [String]         // 一時勘定（損益、現金過不足等）

    enum CodingKeys: String, CodingKey {
        case assets, liabilities, equity, revenue, expenses, temporary
        case contraAssets = "contra_assets"
    }

    /// 全勘定科目をフラットな配列で取得
    var allAccounts: [String] {
        assets + contraAssets + liabilities + equity + revenue + expenses + temporary
    }
}

/// ダミー選択肢の生成ルール — CBT第1問のプルダウン用
struct DummyGenerationRules: Codable {
    let description: String
    let strategy: [String]
    let confusingPairs: [[String]]  // 紛らわしい科目ペア（18組）

    enum CodingKeys: String, CodingKey {
        case description, strategy
        case confusingPairs = "confusing_pairs"
    }
}

/// 補助簿マスタ — 第2問の補助簿選択で使用
struct SubledgerMaster: Codable {
    let description: String
    let subledgers: [SubledgerInfo]
}

/// 補助簿の情報
struct SubledgerInfo: Codable {
    let name: String        // 補助簿名（例: "現金出納帳"）
    let records: String     // 記録内容の説明
}

/// 理論穴埋めトピック — 第2問の理論問題で使用
struct TheoryTopics: Codable {
    let description: String
    let topics: [TheoryTopic]
}

/// 理論トピック（帳簿組織、試算表、財務諸表など）
struct TheoryTopic: Codable, Identifiable {
    let id: String
    let title: String
    let keywords: [String]
}

// MARK: - ローダー

/// 勘定科目マスタの読み込みと提供を行うシングルトン
/// - 紛らわしい科目ペアの提供（ダミー選択肢生成用）
/// - 勘定科目の分類判定
/// - 補助簿・理論トピックの参照
class AccountMasterLoader {
    /// シングルトンインスタンス
    static let shared = AccountMasterLoader()

    /// 読み込んだマスタデータ
    private(set) var master: AccountMaster?

    /// 勘定科目名→分類のマッピング（高速検索用）
    private var accountCategoryMap: [String: String] = [:]

    /// 初期化時にJSONを読み込む
    private init() {
        loadMaster()
        buildCategoryMap()
    }

    /// account_master.json を読み込む
    private func loadMaster() {
        do {
            guard let url = Bundle.main.url(forResource: "account_master", withExtension: "json") else {
                #if DEBUG
                print("⚠️ account_master.json がバンドルに見つかりません")
                #endif
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            master = try decoder.decode(AccountMaster.self, from: data)

            #if DEBUG
            print("✅ 勘定科目マスタ読み込み完了: \(master?.accounts.allAccounts.count ?? 0)科目")
            #endif
        } catch {
            #if DEBUG
            print("❌ 勘定科目マスタ読み込みエラー: \(error)")
            #endif
        }
    }

    /// 勘定科目→分類のマッピングを構築する
    private func buildCategoryMap() {
        guard let accounts = master?.accounts else { return }
        for name in accounts.assets { accountCategoryMap[name] = "資産" }
        for name in accounts.contraAssets { accountCategoryMap[name] = "資産のマイナス" }
        for name in accounts.liabilities { accountCategoryMap[name] = "負債" }
        for name in accounts.equity { accountCategoryMap[name] = "純資産" }
        for name in accounts.revenue { accountCategoryMap[name] = "収益" }
        for name in accounts.expenses { accountCategoryMap[name] = "費用" }
        for name in accounts.temporary { accountCategoryMap[name] = "一時勘定" }
    }

    // MARK: - 公開API

    /// 指定した勘定科目の分類名を返す（該当なしは nil）
    func categoryName(for account: String) -> String? {
        accountCategoryMap[account]
    }

    /// 紛らわしい科目ペアを取得（ダミー選択肢の生成に使用）
    var confusingPairs: [[String]] {
        master?.dummyGenerationRules.confusingPairs ?? []
    }

    /// 指定した勘定科目の「紛らわしい相手」を返す（ダミー選択肢用）
    func confusingCounterpart(for account: String) -> String? {
        for pair in confusingPairs {
            guard pair.count == 2 else { continue }
            if pair[0] == account { return pair[1] }
            if pair[1] == account { return pair[0] }
        }
        return nil
    }

    /// 補助簿リストを取得
    var subledgers: [SubledgerInfo] {
        master?.subledgerMaster.subledgers ?? []
    }

    /// 理論トピックリストを取得
    var theoryTopics: [TheoryTopic] {
        master?.theoryTopics.topics ?? []
    }

    /// 全勘定科目名リスト
    var allAccountNames: [String] {
        master?.accounts.allAccounts ?? []
    }
}
