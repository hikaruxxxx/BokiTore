import Foundation
import SwiftData

/// 実力診断結果 — CAT（コンピュータ適応型テスト）の結果を保存
/// 将来の「実力診断モード」「レーダーチャート」で活用する
@Model
class DiagnosisResult {
    /// 診断を実施した日時
    var diagnosedAt: Date
    /// 総合スコア（0〜100）
    var overallScore: Int
    /// 推定合格確率（0.0〜1.0）
    var estimatedPassRate: Double
    /// カテゴリ別スコアのJSON文字列
    /// 形式: [{"category": "現金取引", "score": 85, "totalQuestions": 10, "correctCount": 8}]
    var categoryScoresJSON: String?
    /// 診断に使った問題数
    var totalQuestions: Int
    /// 正答数
    var correctCount: Int
    /// 診断にかかった時間（秒）
    var durationSec: Int
    /// 弱点カテゴリのリスト（JSON配列文字列: ["手形取引", "決算整理"]）
    var weakCategoriesJSON: String?

    init(
        diagnosedAt: Date = .now,
        overallScore: Int = 0,
        estimatedPassRate: Double = 0.0,
        categoryScoresJSON: String? = nil,
        totalQuestions: Int = 0,
        correctCount: Int = 0,
        durationSec: Int = 0,
        weakCategoriesJSON: String? = nil
    ) {
        self.diagnosedAt = diagnosedAt
        self.overallScore = overallScore
        self.estimatedPassRate = estimatedPassRate
        self.categoryScoresJSON = categoryScoresJSON
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.durationSec = durationSec
        self.weakCategoriesJSON = weakCategoriesJSON
    }

    // MARK: - JSON ヘルパー（StudyPlanと同パターン）

    /// カテゴリ別スコアをデコードして取得
    func getCategoryScores() -> [CategoryScore] {
        guard let json = categoryScoresJSON,
              let data = json.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([CategoryScore].self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ カテゴリスコアのデコードエラー: \(error)")
            #endif
            return []
        }
    }

    /// カテゴリ別スコアをエンコードして保存
    func setCategoryScores(_ scores: [CategoryScore]) {
        do {
            let data = try JSONEncoder().encode(scores)
            categoryScoresJSON = String(data: data, encoding: .utf8)
        } catch {
            #if DEBUG
            print("⚠️ カテゴリスコアのエンコードエラー: \(error)")
            #endif
        }
    }

    /// 弱点カテゴリをデコードして取得
    func getWeakCategories() -> [String] {
        guard let json = weakCategoriesJSON,
              let data = json.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ 弱点カテゴリのデコードエラー: \(error)")
            #endif
            return []
        }
    }

    /// 弱点カテゴリをエンコードして保存
    func setWeakCategories(_ categories: [String]) {
        do {
            let data = try JSONEncoder().encode(categories)
            weakCategoriesJSON = String(data: data, encoding: .utf8)
        } catch {
            #if DEBUG
            print("⚠️ 弱点カテゴリのエンコードエラー: \(error)")
            #endif
        }
    }
}

/// カテゴリ別スコア（DiagnosisResult内のJSON用）
struct CategoryScore: Codable {
    let category: String        // "現金取引"
    let score: Int              // 85
    let totalQuestions: Int      // 10
    let correctCount: Int       // 8
}
