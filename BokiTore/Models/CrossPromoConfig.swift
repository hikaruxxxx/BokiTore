import Foundation

/// クロスプロモーション設定のルート構造体
/// アプリ内にバンドルされたJSONから読み込む
struct CrossPromoConfig: Codable {
    /// バナー一覧
    let banners: [CrossPromoItem]
    /// 表示頻度（"once_per_session" / "always"）
    let showFrequency: String
}

/// 個別のプロモーションバナー情報
struct CrossPromoItem: Codable, Identifiable {
    /// 一意のID
    let id: String
    /// バナータイトル（例: "FP技能検定にも挑戦！"）
    let title: String
    /// サブタイトル（例: "簿記の次はFP"）
    let subtitle: String
    /// App Store URL
    let appStoreUrl: String
    /// アイコン画像名（Assets.xcassets内）
    let iconName: String
    /// 表示有効フラグ（falseで非表示）
    let enabled: Bool
    /// ターゲット資格（nil = 全ユーザー対象、例: ["fp", "takken"]）
    let targetCerts: [String]?
    /// ターゲット学習目的（nil = 全ユーザー対象、例: ["career_up", "job_hunting"]）
    let targetPurposes: [String]?
    /// 表示配置（nil = すべての場所で表示、"home" / "quiz_result" / "settings"）
    let placement: String?
}
