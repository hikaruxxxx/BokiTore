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

    /// QuestionBank.jsonからデータを読み込む
    private func loadQuestions() {
        do {
            // バンドル内のJSONファイルを探す
            guard let url = Bundle.main.url(forResource: "QuestionBank", withExtension: "json") else {
                assertionFailure("QuestionBank.jsonがバンドルに含まれていません。ビルド設定を確認してください。")
                #if DEBUG
                print("QuestionBank.jsonが見つかりません")
                #endif
                return
            }

            // JSONデータを読み込む
            let data = try Data(contentsOf: url)

            // JSONをデコードする
            let decoder = JSONDecoder()
            let bank = try decoder.decode(QuestionBank.self, from: data)
            allQuestions = bank.questions

            #if DEBUG
            print("問題データ読み込み完了: \(allQuestions.count)問")
            #endif
        } catch {
            #if DEBUG
            print("問題データ読み込みエラー: \(error)")
            #endif
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
}
