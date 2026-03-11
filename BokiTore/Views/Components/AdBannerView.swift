import SwiftUI
import GoogleMobileAds

// MARK: - AdMobバナー広告ビュー

/// AdMobバナー広告をSwiftUIで表示するためのラッパー
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = Constants.AdMob.bannerAdUnitId

        // 最前面のViewControllerをrootVCとして設定
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }

        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

/// バナー広告表示（プレミアム会員の場合は非表示にする共通ビュー）
struct AdBannerPlaceholder: View {
    var body: some View {
        #if DEBUG
        // デバッグ時はプレースホルダーを表示（AdMob SDKが入っていない場合のフォールバック）
        Rectangle()
            .fill(Color(.tertiarySystemBackground))
            .frame(height: 50)
            .overlay(
                Text("広告バナー")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            )
        #else
        // リリースビルドではAdMobバナーを表示
        AdBannerView()
            .frame(height: 50)
        #endif
    }
}

#Preview {
    AdBannerPlaceholder()
}
