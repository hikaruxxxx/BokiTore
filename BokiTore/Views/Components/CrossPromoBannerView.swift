import SwiftUI

/// クロスプロモーションバナー表示View
/// ターゲティングパラメータに基づいて表示するプロモーションを選択する
struct CrossPromoBannerView: View {
    /// 表示するプロモーション一覧
    private let promos: [CrossPromoItem]
    /// 表示配置（Analytics用）
    private let placement: String

    /// ターゲティング付きイニシャライザ
    /// - Parameters:
    ///   - placement: 表示配置（"home", "quiz_result", "settings"）
    ///   - userCerts: ユーザーが興味のある資格一覧
    ///   - userPurpose: ユーザーの学習目的
    init(placement: String = "home",
         userCerts: [String] = [],
         userPurpose: String = "") {
        self.placement = placement
        self.promos = CrossPromoLoader.displayablePromos(
            for: placement,
            userCerts: userCerts,
            userPurpose: userPurpose
        )
    }

    var body: some View {
        // 表示可能なプロモーションがない場合は何も表示しない
        if !promos.isEmpty {
            VStack(spacing: 8) {
                ForEach(promos) { promo in
                    if let url = URL(string: promo.appStoreUrl) {
                        Link(destination: url) {
                            promoBannerCard(promo)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            // Firebase Analyticsにアフィリエイトタップイベントを送信
                            AnalyticsManager.logAffiliateTapped(
                                promoId: promo.id,
                                sourceScreen: placement
                            )
                        })
                    }
                }
            }
        }
    }

    /// プロモーションバナーカード
    @ViewBuilder
    private func promoBannerCard(_ promo: CrossPromoItem) -> some View {
        HStack(spacing: 12) {
            // アイコン（Assetsにアイコンがない場合はSFSymbol）
            Image(systemName: "app.fill")
                .font(.title)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 44, height: 44)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(promo.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(promo.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CrossPromoBannerView(
        placement: "home",
        userCerts: ["fp"],
        userPurpose: "career_up"
    )
    .padding()
}
