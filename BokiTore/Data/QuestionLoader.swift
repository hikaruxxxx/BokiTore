import Foundation

/// 問題データをJSONから読み込むクラス
/// アプリ起動時に一度だけ読み込み、メモリ上にキャッシュする
class QuestionLoader {
    /// シングルトンインスタンス
    static let shared = QuestionLoader()

    /// 読み込んだ全問題データ
    private(set) var allQuestions: [Question] = []

    /// 初期化時にJSONを読み込む
    private init() {
        loadQuestions()
    }

    /// 読み込むJSONファイル名リスト（バンドル内に存在するもののみ読込）
    private static let questionFiles = [
        "QuestionBank",              // 既存50問（multipleChoice）
        "questions_dai1_shiwake",    // 第1問: CBT仕訳入力（300問）
        "questions_dai2_kanjou",     // 第2問⑴: T勘定空欄補充（100問）
        "questions_dai2_hojo",       // 第2問⑵-A: 補助簿選択（50問）
        "questions_dai2_riron",      // 第2問⑵-B: 理論穴埋め（50問）
    ]

    /// 複数のJSONファイルから問題データを読み込む
    private func loadQuestions() {
        var loaded: [Question] = []

        for fileName in Self.questionFiles {
            let questions = loadFromFile(fileName)
            loaded.append(contentsOf: questions)
        }

        // 最低限QuestionBankは必須
        if loaded.isEmpty {
            assertionFailure("問題データが1つも読み込めませんでした。JSONファイルを確認してください。")
        }

        allQuestions = loaded

        #if DEBUG
        print("問題データ読み込み完了: \(allQuestions.count)問（\(Self.questionFiles.count)ファイル）")
        #endif
    }

    /// 個別のJSONファイルから問題を読み込む（ファイル未存在時は空配列を返す）
    private func loadFromFile(_ name: String) -> [Question] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            #if DEBUG
            print("\(name).json — バンドルに未登録（スキップ）")
            #endif
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let bank = try JSONDecoder().decode(QuestionBank.self, from: data)
            #if DEBUG
            print("\(name).json — \(bank.questions.count)問読み込み")
            #endif
            return bank.questions
        } catch {
            #if DEBUG
            print("\(name).json — 読み込みエラー: \(error)")
            #endif
            return []
        }
    }

    /// 指定カテゴリの問題を取得
    func questions(for category: String) -> [Question] {
        allQuestions.filter { $0.category == category }
    }

    /// 指定サブカテゴリの問題を取得
    func questions(forSubcategory subcategory: String) -> [Question] {
        allQuestions.filter { $0.subcategory == subcategory }
    }

    /// 指定難易度の問題を取得
    func questions(forDifficulty difficulty: Int) -> [Question] {
        allQuestions.filter { $0.difficulty == difficulty }
    }

    /// ランダムに指定数の問題を取得
    func randomQuestions(count: Int) -> [Question] {
        Array(allQuestions.shuffled().prefix(count))
    }

    /// 間違えた問題IDから問題を取得
    func questions(byIds ids: [String]) -> [Question] {
        allQuestions.filter { ids.contains($0.id) }
    }

    /// 指定タグを含む問題を取得
    func questions(forTag tag: String) -> [Question] {
        allQuestions.filter { $0.tags.contains(tag) }
    }

    // MARK: - セクション・フォーマット別フィルタ

    /// 試験セクション別の問題を取得（例: "第1問", "第2問⑴"）
    func questions(forExamSection section: String) -> [Question] {
        allQuestions.filter { $0.examSection == section }
    }

    /// フォーマット別の問題を取得
    func questions(forFormat format: QuestionFormat) -> [Question] {
        allQuestions.filter { $0.effectiveFormat == format }
    }

    /// 全問題のユニークなタグ一覧
    var allTags: [String] {
        Array(Set(allQuestions.flatMap { $0.tags })).sorted()
    }

    /// 全問題のユニークなサブカテゴリ一覧
    var allSubcategories: [String] {
        Array(Set(allQuestions.map { $0.subcategory })).sorted()
    }

    /// 全問題のユニークな試験セクション一覧
    var allExamSections: [String] {
        Array(Set(allQuestions.compactMap { $0.examSection })).sorted()
    }
}
