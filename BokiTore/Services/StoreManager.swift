import Foundation
import StoreKit

/// サブスクリプション管理（StoreKit 2）
/// 月額480円のプレミアムプランを管理する
@Observable
class StoreManager {
    /// シングルトンインスタンス
    static let shared = StoreManager()

    /// プレミアム会員かどうか
    var isPremium = false

    /// 利用可能なプロダクト
    var products: [Product] = []

    /// 購入処理中かどうか
    var isPurchasing = false

    /// エラーメッセージ
    var errorMessage: String?

    /// トランザクション監視タスク
    private var transactionListener: Task<Void, Never>?

    private init() {
        // トランザクション更新を監視する
        transactionListener = listenForTransactions()
        // 起動時に購入状態を確認
        Task {
            await checkCurrentEntitlements()
            await fetchProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - トランザクション監視

    /// トランザクション更新を監視する（自動更新・返金等を検出）
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                if case .verified(let transaction) = result {
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    /// 検証済みトランザクションを処理する
    @MainActor
    private func handleVerifiedTransaction(_ transaction: Transaction) {
        if Constants.Store.allProductIds.contains(transaction.productID) {
            // 有効期限チェック（返金・キャンセルの場合はrevocationDateが設定される）
            if transaction.revocationDate == nil {
                isPremium = true
                AdManager.shared.isAdFree = true
            } else {
                isPremium = false
                AdManager.shared.isAdFree = false
            }
        }
    }

    // MARK: - プロダクト取得

    /// プロダクト情報をApp Store Connectから取得する
    func fetchProducts() async {
        do {
            products = try await Product.products(for: Constants.Store.allProductIds)
        } catch {
            #if DEBUG
            print("プロダクト取得エラー: \(error)")
            #endif
        }
    }

    // MARK: - 購入処理

    /// サブスクリプションを購入する
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await handleVerifiedTransaction(transaction)
                await transaction.finish()
                isPurchasing = false
                return true

            case .pending:
                // 承認待ち（ファミリー共有の承認等）
                errorMessage = "購入が承認待ちです"
                isPurchasing = false
                return false

            case .userCancelled:
                isPurchasing = false
                return false

            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            #if DEBUG
            print("購入エラー: \(error)")
            #endif
            errorMessage = "購入に失敗しました"
            isPurchasing = false
            return false
        }
    }

    // MARK: - 復元

    /// 購入状態を復元する
    @MainActor
    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        // 最新のトランザクションを同期
        do {
            try await AppStore.sync()
        } catch {
            #if DEBUG
            print("App Store同期エラー: \(error)")
            #endif
        }

        await checkCurrentEntitlements()
        isPurchasing = false

        if !isPremium {
            errorMessage = "復元可能な購入が見つかりませんでした"
        }
    }

    /// 現在の権限を確認する
    @MainActor
    private func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if Constants.Store.allProductIds.contains(transaction.productID),
                   transaction.revocationDate == nil {
                    isPremium = true
                    AdManager.shared.isAdFree = true
                    return
                }
            }
        }
    }

    /// 月額プロダクト
    var monthlyProduct: Product? {
        products.first { $0.id == Constants.Store.premiumMonthlyProductId }
    }

    /// 年間プロダクト
    var yearlyProduct: Product? {
        products.first { $0.id == Constants.Store.premiumYearlyProductId }
    }

    /// プレミアムプランの月額表示テキスト
    var premiumPriceText: String {
        guard let product = monthlyProduct else { return "¥480/月" }
        return product.displayPrice + "/月"
    }

    /// プレミアムプランの年間表示テキスト
    var premiumYearlyPriceText: String {
        guard let product = yearlyProduct else { return "¥2,000/年" }
        return product.displayPrice + "/年"
    }
}
