import StoreKit

/// レビュー誘導マネージャー
/// 複数条件を満たした最適なタイミングでApp Storeレビューを依頼する
///
/// 条件:
/// 1. 累計正解数 ≥ 50問
/// 2. アプリ利用日数 ≥ 3日
/// 3. 直近セッション正答率 ≥ 70%
/// 4. 前回のレビュー依頼から30日以上経過
/// 5. 年間3回まで（Appleガイドライン準拠）
enum ReviewManager {

    // MARK: - 定数

    /// 累計正解数のしきい値
    private static let minCorrectAnswers = 50
    /// アプリ利用日数のしきい値
    private static let minUsageDays = 3
    /// 直近セッション正答率のしきい値（0.0〜1.0）
    private static let minSessionAccuracy = 0.7
    /// レビュー依頼のクールダウン（日数）
    private static let cooldownDays = 30
    /// 年間最大依頼回数（Apple制限）
    private static let maxRequestsPerYear = 3

    // MARK: - UserDefaultsキー

    private static let firstLaunchDateKey = "reviewManager_firstLaunchDate"
    private static let lastRequestDateKey = "reviewManager_lastRequestDate"
    private static let requestCountKey = "reviewManager_requestCount"
    private static let requestYearKey = "reviewManager_requestYear"

    // MARK: - 初期化

    /// アプリ初回起動日を記録する（BokiToreApp.init() から呼ぶ）
    static func registerFirstLaunchIfNeeded() {
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: firstLaunchDateKey)
        }
    }

    // MARK: - レビュー判定

    /// セッション完了時に呼ぶ。全条件を満たせばレビューダイアログを表示する
    /// - Parameters:
    ///   - totalCorrect: 累計正解数
    ///   - studyDays: アプリ利用日数（StudyStreakのレコード数）
    ///   - sessionAccuracy: 直近セッションの正答率（0.0〜1.0）
    static func requestReviewIfEligible(
        totalCorrect: Int,
        studyDays: Int,
        sessionAccuracy: Double
    ) {
        // 条件1: 累計正解数
        guard totalCorrect >= minCorrectAnswers else { return }

        // 条件2: アプリ利用日数
        guard studyDays >= minUsageDays else { return }

        // 条件3: 直近セッション正答率
        guard sessionAccuracy >= minSessionAccuracy else { return }

        // 条件4: クールダウン期間
        guard hasCooldownPassed() else { return }

        // 条件5: 年間回数制限
        guard canRequestThisYear() else { return }

        // 全条件クリア — レビューダイアログを表示
        recordRequest()
        requestReview()

        #if DEBUG
        print("⭐ ReviewManager: レビュー依頼を表示しました")
        #endif
    }

    // MARK: - 条件チェック

    /// 前回のレビュー依頼からクールダウン期間が経過したか
    private static func hasCooldownPassed() -> Bool {
        let lastTimestamp = UserDefaults.standard.double(forKey: lastRequestDateKey)
        // まだ一度もリクエストしていない場合はOK
        guard lastTimestamp > 0 else { return true }
        let lastDate = Date(timeIntervalSince1970: lastTimestamp)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
        return daysSince >= cooldownDays
    }

    /// 今年の残り回数があるか
    private static func canRequestThisYear() -> Bool {
        let currentYear = Calendar.current.component(.year, from: .now)
        let savedYear = UserDefaults.standard.integer(forKey: requestYearKey)

        // 年が変わっていたらカウントリセット
        if savedYear != currentYear {
            return true
        }

        let count = UserDefaults.standard.integer(forKey: requestCountKey)
        return count < maxRequestsPerYear
    }

    // MARK: - 記録

    /// レビュー依頼の実行を記録する
    private static func recordRequest() {
        let currentYear = Calendar.current.component(.year, from: .now)
        let savedYear = UserDefaults.standard.integer(forKey: requestYearKey)

        if savedYear != currentYear {
            // 新しい年 → カウントをリセット
            UserDefaults.standard.set(currentYear, forKey: requestYearKey)
            UserDefaults.standard.set(1, forKey: requestCountKey)
        } else {
            // 同じ年 → カウント加算
            let count = UserDefaults.standard.integer(forKey: requestCountKey)
            UserDefaults.standard.set(count + 1, forKey: requestCountKey)
        }

        // 最終依頼日を更新
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: lastRequestDateKey)
    }

    // MARK: - レビューダイアログ表示

    /// App Storeレビューダイアログを表示する
    private static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}
