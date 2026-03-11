import Foundation

/// アプリ全体で使う定数
enum Constants {
    // MARK: - AdMob広告ユニットID
    // 本番IDはApp Store申請前に差し替えること
    enum AdMob {
        /// バナー広告（テスト用ID）
        static let bannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"
        /// インタースティシャル広告（テスト用ID）
        static let interstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
        /// リワード動画広告（テスト用ID）
        static let rewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    }

    // MARK: - アプリ設定
    enum App {
        /// インタースティシャル広告を表示する間隔（問題数）
        static let interstitialInterval = 10
        /// 1セッションのデフォルト問題数
        static let defaultQuestionCount = 10
    }

    // MARK: - StoreKit
    enum Store {
        /// サブスクリプションのプロダクトID
        static let premiumMonthlyProductId = "com.bokitore.premium.monthly"
    }

    // MARK: - ゲーミフィケーション設定
    enum Gamification {
        /// 復習の間隔（日数）: 1日後→3日後→7日後
        static let reviewIntervals = [1, 3, 7]
        /// タイムアタックの制限時間（秒）
        static let timeAttackDuration = 60
        /// デイリーチャレンジのミッション数
        static let dailyMissionCount = 3
        /// マスタリーランクの閾値（名前, 必要問題数, 必要正答率）
        static let masteryThresholds: [(name: String, minCount: Int, minAccuracy: Double)] = [
            ("Bronze", 10, 0.8),
            ("Silver", 25, 0.8),
            ("Gold", 50, 0.8),
            ("Master", 100, 0.8)
        ]

        /// ストリークマイルストーン定義（日数, ランク名, SFSymbol）
        static let streakMilestones: [(days: Int, rank: String, icon: String)] = [
            (7, "Bronze", "flame.fill"),
            (30, "Silver", "flame.fill"),
            (100, "Gold", "flame.fill"),
            (365, "Master", "crown.fill")
        ]

        /// 正解時の励ましメッセージ
        static let correctMessages = ["すごい！", "正解！", "その調子！", "完璧！"]
        /// 不正解時の励ましメッセージ
        static let incorrectMessages = ["惜しい！", "次こそ！", "復習しよう！"]

        /// クイズ結果のランクタイトル（正答率に応じて付与、上から順にチェック）
        static let resultRanks: [(minAccuracy: Double, title: String, subtitle: String)] = [
            (1.0, "完璧", "すべて正解！"),
            (0.8, "優秀", "よくできました！"),
            (0.6, "好調", "その調子！"),
            (0.4, "成長中", "着実に前進中！"),
            (0.0, "挑戦者", "復習して強くなろう！")
        ]
    }

    // MARK: - URL
    enum URLs {
        /// プライバシーポリシー
        static let privacyPolicy = "https://hikaruxxxx.github.io/BokiTore/privacy.html"
        /// 利用規約
        static let termsOfService = "https://hikaruxxxx.github.io/BokiTore/terms.html"
    }
}
