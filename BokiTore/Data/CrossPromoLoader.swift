import Foundation

/// クロスプロモーションJSON設定の読み込み
enum CrossPromoLoader {
    /// バンドル内のCrossPromoConfig.jsonを読み込む
    /// - Returns: 設定オブジェクト。読み込み失敗時はnil
    static func load() -> CrossPromoConfig? {
        guard let url = Bundle.main.url(forResource: "CrossPromoConfig", withExtension: "json") else {
            #if DEBUG
            print("⚠️ CrossPromo: CrossPromoConfig.json が見つかりません")
            #endif
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(CrossPromoConfig.self, from: data)
            return config
        } catch {
            #if DEBUG
            print("⚠️ CrossPromo: JSON読み込みエラー: \(error)")
            #endif
            return nil
        }
    }

    /// 表示可能なプロモーション一覧を取得する
    /// enabled: true のバナーのみ返す
    static func displayablePromos() -> [CrossPromoItem] {
        guard let config = load() else { return [] }
        return config.banners.filter { $0.enabled }
    }

    /// ターゲティングフィルタ付きの表示可能プロモーション一覧を取得する
    /// - Parameters:
    ///   - placement: 表示配置（"home", "quiz_result", "settings"）
    ///   - userCerts: ユーザーが興味のある資格一覧
    ///   - userPurpose: ユーザーの学習目的
    /// - Returns: ターゲティング条件に一致するプロモーション一覧
    static func displayablePromos(
        for placement: String,
        userCerts: [String],
        userPurpose: String
    ) -> [CrossPromoItem] {
        guard let config = load() else { return [] }
        return config.banners.filter { banner in
            // enabledでない場合は除外
            guard banner.enabled else { return false }

            // placement フィルタ（nil = すべての場所で表示）
            if let bannerPlacement = banner.placement,
               bannerPlacement != placement {
                return false
            }

            // targetCerts フィルタ（nil = 全ユーザー対象）
            if let targets = banner.targetCerts,
               !targets.isEmpty {
                // ユーザーの興味資格と一つでも一致すれば表示
                let matched = !Set(targets).isDisjoint(with: Set(userCerts))
                if !matched { return false }
            }

            // targetPurposes フィルタ（nil = 全ユーザー対象）
            if let purposes = banner.targetPurposes,
               !purposes.isEmpty {
                if !purposes.contains(userPurpose) { return false }
            }

            return true
        }
    }
}
