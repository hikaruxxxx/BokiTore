import SwiftUI

/// 設定画面
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationStack {
            List {
                // プレミアムプラン
                PremiumSection()

                // 表示設定
                Section("表示") {
                    Toggle("ダークモード", isOn: $isDarkMode)
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }

                // リンク
                Section {
                    Link("プライバシーポリシー", destination: URL(string: Constants.URLs.privacyPolicy)!)
                    Link("利用規約", destination: URL(string: Constants.URLs.termsOfService)!)
                }
            }
            .navigationTitle("設定")
        }
    }

    /// アプリのバージョンを取得
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/// プレミアムプランセクション
struct PremiumSection: View {
    private var store = StoreManager.shared

    var body: some View {
        Section {
            if store.isPremium {
                // プレミアム会員の場合
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("プレミアム会員")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("有効")
                        .foregroundStyle(Color.appSecondary)
                        .fontWeight(.semibold)
                }
            } else {
                // 未購入の場合
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("プレミアムプラン")
                            .fontWeight(.bold)
                    }

                    // メリット一覧
                    VStack(alignment: .leading, spacing: 4) {
                        PremiumFeatureRow(text: "広告の完全非表示")
                        PremiumFeatureRow(text: "全カテゴリの詳細分析")
                    }
                    .padding(.vertical, 4)

                    // 購入ボタン
                    Button {
                        Task {
                            if let product = store.products.first {
                                _ = await store.purchase(product)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if store.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("\(store.premiumPriceText)で購入")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(store.isPurchasing || store.products.isEmpty)

                    // エラーメッセージ
                    if let error = store.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.appError)
                    }
                }

                // 購入を復元
                Button("購入を復元") {
                    Task {
                        await store.restorePurchases()
                    }
                }
                .font(.subheadline)
                .disabled(store.isPurchasing)
            }
        } header: {
            Text("プレミアム")
        } footer: {
            if !store.isPremium {
                Text("サブスクリプションは自動更新されます。管理はiOSの設定から行えます。")
            }
        }
    }
}

/// プレミアム機能の行
struct PremiumFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appSecondary)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
