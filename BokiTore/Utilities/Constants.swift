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

    // MARK: - URL
    enum URLs {
        /// プライバシーポリシー
        static let privacyPolicy = "https://example.com/privacy"
        /// 利用規約
        static let termsOfService = "https://example.com/terms"
    }
}
