import StoreKit

/// レビュー誘導マネージャー
/// 適切なタイミングでApp Storeレビューを依頼する
enum ReviewManager {
    /// レビュー依頼のしきい値（解答数）
    private static let reviewThreshold = 30

    /// レビュー済みかどうかのキー
    private static let hasRequestedReviewKey = "hasRequestedReview"

    /// レビューを依頼すべきか判定して、条件を満たせばリクエスト
    static func requestReviewIfNeeded(answeredCount: Int) {
        // 既にリクエスト済みなら何もしない
        guard !UserDefaults.standard.bool(forKey: hasRequestedReviewKey) else { return }

        // しきい値に達したらリクエスト
        if answeredCount >= reviewThreshold {
            requestReview()
            UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        }
    }

    /// App Storeレビューダイアログを表示
    private static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}
