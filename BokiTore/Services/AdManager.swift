import Foundation
import SwiftUI
import GoogleMobileAds

/// 広告管理マネージャー
/// Google AdMob SDKを使ったバナー/インタースティシャル/リワード広告の管理
@Observable
class AdManager: NSObject {
    /// シングルトンインスタンス
    static let shared = AdManager()

    /// 広告非表示（プレミアム会員）かどうか
    var isAdFree = false

    /// 解答した問題数（インタースティシャル表示判定用）
    var answeredCount = 0

    /// インタースティシャル広告のインスタンス
    private var interstitialAd: GADInterstitialAd?

    /// リワード広告のインスタンス
    private var rewardedAd: GADRewardedAd?

    /// 広告の読み込み状態
    var isInterstitialReady = false
    var isRewardedReady = false

    private override init() {
        super.init()
    }

    /// AdMob SDKを初期化する（AppDelegateまたはApp起動時に呼ぶ）
    func configure() {
        GADMobileAds.sharedInstance().start { status in
            #if DEBUG
            print("AdMob SDK初期化完了: \(status.adapterStatusesByClassName)")
            #endif
        }
        // 初回の広告を読み込む
        loadInterstitial()
        loadRewarded()
    }

    /// インタースティシャル広告を表示すべきか判定
    var shouldShowInterstitial: Bool {
        !isAdFree && answeredCount > 0 && answeredCount % Constants.App.interstitialInterval == 0
    }

    /// 解答数をインクリメント
    func incrementAnswerCount() {
        answeredCount += 1
    }

    // MARK: - インタースティシャル広告

    /// インタースティシャル広告を読み込む
    func loadInterstitial() {
        guard !isAdFree else { return }

        GADInterstitialAd.load(
            withAdUnitID: Constants.AdMob.interstitialAdUnitId,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                #if DEBUG
                print("インタースティシャル読み込みエラー: \(error)")
                #endif
                self.isInterstitialReady = false
                return
            }
            self.interstitialAd = ad
            self.isInterstitialReady = true
        }
    }

    /// インタースティシャル広告を表示する
    func showInterstitial() {
        guard !isAdFree, let ad = interstitialAd else {
            loadInterstitial()
            return
        }

        guard let topVC = Self.topViewController() else { return }
        ad.present(fromRootViewController: topVC)
        isInterstitialReady = false
        loadInterstitial()
    }

    // MARK: - リワード広告

    /// リワード広告を読み込む
    func loadRewarded() {
        guard !isAdFree else { return }

        GADRewardedAd.load(
            withAdUnitID: Constants.AdMob.rewardedAdUnitId,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                #if DEBUG
                print("リワード広告読み込みエラー: \(error)")
                #endif
                self.isRewardedReady = false
                return
            }
            self.rewardedAd = ad
            self.isRewardedReady = true
        }
    }

    /// リワード広告を表示する（完了コールバックで報酬の有無を返す）
    func showRewarded(completion: @escaping (Bool) -> Void) {
        guard !isAdFree, let ad = rewardedAd else {
            completion(false)
            loadRewarded()
            return
        }

        guard let topVC = Self.topViewController() else {
            completion(false)
            return
        }

        ad.present(fromRootViewController: topVC) {
            let reward = ad.adReward
            completion(reward.amount.doubleValue > 0)
        }

        isRewardedReady = false
        loadRewarded()
    }

    // MARK: - ヘルパー

    /// 最前面のViewControllerを取得する（広告表示用）
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.keyWindow?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}
