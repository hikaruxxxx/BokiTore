import Foundation
import SwiftData

/// 学習ロードマップ — 実力診断結果に基づく個別最適化された学習計画
/// 将来の「AI学習アドバイザー」「おすすめ出題」で活用する
@Model
class StudyRoadmap {
    /// ロードマップ作成日時
    var createdAt: Date
    /// 基になった診断結果の日時（DiagnosisResultとの紐付け用）
    var basedOnDiagnosisAt: Date?
    /// 目標試験日（StudyPlanからコピー、未設定はnil）
    var targetExamDate: Date?
    /// 学習ステップのJSON配列文字列
    /// 形式: [{"order": 1, "category": "現金取引", "priority": "high", "targetScore": 80, "currentScore": 45, "isCompleted": false}]
    var stepsJSON: String?
    /// ロードマップ全体の達成率（0.0〜1.0）
    var completionRate: Double
    /// ロードマップが有効かどうか（新しい診断で更新されたら古いものは無効化）
    var isActive: Bool

    init(
        createdAt: Date = .now,
        basedOnDiagnosisAt: Date? = nil,
        targetExamDate: Date? = nil,
        stepsJSON: String? = nil,
        completionRate: Double = 0.0,
        isActive: Bool = true
    ) {
        self.createdAt = createdAt
        self.basedOnDiagnosisAt = basedOnDiagnosisAt
        self.targetExamDate = targetExamDate
        self.stepsJSON = stepsJSON
        self.completionRate = completionRate
        self.isActive = isActive
    }

    // MARK: - JSON ヘルパー

    /// 学習ステップをデコードして取得
    func getSteps() -> [RoadmapStep] {
        guard let json = stepsJSON,
              let data = json.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([RoadmapStep].self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ ロードマップステップのデコードエラー: \(error)")
            #endif
            return []
        }
    }

    /// 学習ステップをエンコードして保存
    func setSteps(_ steps: [RoadmapStep]) {
        do {
            let data = try JSONEncoder().encode(steps)
            stepsJSON = String(data: data, encoding: .utf8)
        } catch {
            #if DEBUG
            print("⚠️ ロードマップステップのエンコードエラー: \(error)")
            #endif
        }
    }
}

/// ロードマップの個別ステップ（StudyRoadmap内のJSON用）
struct RoadmapStep: Codable {
    let order: Int              // 学習順序（1〜）
    let category: String        // "現金取引"
    let priority: String        // "high", "medium", "low"
    let targetScore: Int        // 目標スコア（80）
    var currentScore: Int       // 現在のスコア（45）
    var isCompleted: Bool       // 目標達成済みか
}
