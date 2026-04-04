import SwiftUI
import SwiftData

/// 設定画面
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isSoundEnabled") private var isSoundEnabled = true
    @AppStorage("isHapticEnabled") private var isHapticEnabled = true
    @Query private var studyPlans: [StudyPlan]
    @State private var showStudyPlanEdit = false

    /// 学習計画（1つだけ存在する想定）
    private var studyPlan: StudyPlan? {
        studyPlans.first { $0.isOnboardingCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                // プレミアムプラン
                PremiumSection()

                // 学習計画
                Section("学習計画") {
                    if let plan = studyPlan {
                        HStack {
                            Text("1日の目標")
                            Spacer()
                            Text("\(plan.dailyGoal)問")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("学習時間")
                            Spacer()
                            Text(String(format: "%d:%02d", plan.preferredHour, plan.preferredMinute))
                                .foregroundStyle(.secondary)
                        }
                        if let examDate = plan.examDate {
                            HStack {
                                Text("試験日")
                                Spacer()
                                Text(examDate.formattedDate)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button("学習計画を編集") {
                            showStudyPlanEdit = true
                        }
                    } else {
                        Button("学習計画を作成") {
                            showStudyPlanEdit = true
                        }
                    }
                }

                // 通知設定
                Section("通知") {
                    NavigationLink("リマインド設定") {
                        NotificationSettingsView()
                    }
                }

                // 表示設定
                Section("表示") {
                    Toggle("ダークモード", isOn: $isDarkMode)
                    Toggle("効果音", isOn: $isSoundEnabled)
                    Toggle("振動フィードバック", isOn: $isHapticEnabled)
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
                    if let privacyURL = URL(string: Constants.URLs.privacyPolicy) {
                        Link("プライバシーポリシー", destination: privacyURL)
                    }
                    if let termsURL = URL(string: Constants.URLs.termsOfService) {
                        Link("利用規約", destination: termsURL)
                    }
                }

                // クロスプロモーション（ターゲティング付き）
                Section {
                    CrossPromoBannerView(
                        placement: "settings",
                        userCerts: studyPlan?.getInterestedCerts() ?? [],
                        userPurpose: studyPlan?.studyPurpose ?? ""
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showStudyPlanEdit) {
                StudyPlanOnboardingView(
                    isEditMode: true,
                    existingPlan: studyPlan
                )
            }
        }
    }

    /// アプリのバージョンを取得
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/// プレミアムプランセクション
struct PremiumSection: View {
    /// StoreManagerをEnvironment経由で取得（シングルトン直接参照を排除）
    @Environment(StoreManager.self) private var store

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

                    // 月額プラン購入ボタン
                    PurchaseButton(
                        label: "\(store.premiumPriceText)で購入",
                        isPurchasing: store.isPurchasing,
                        isDisabled: store.isPurchasing || store.monthlyProduct == nil
                    ) {
                        AnalyticsManager.logSubscriptionTapped(screenName: "settings")
                        Task {
                            if let product = store.monthlyProduct {
                                _ = await store.purchase(product)
                            }
                        }
                    }

                    // 年間プラン購入ボタン
                    PurchaseButton(
                        label: "\(store.premiumYearlyPriceText)で購入（お得）",
                        isPurchasing: store.isPurchasing,
                        isDisabled: store.isPurchasing || store.yearlyProduct == nil
                    ) {
                        AnalyticsManager.logSubscriptionTapped(screenName: "settings")
                        Task {
                            if let product = store.yearlyProduct {
                                _ = await store.purchase(product)
                            }
                        }
                    }

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
                VStack(alignment: .leading, spacing: 2) {
                    Text("サブスクリプションは自動更新されます。管理はiOSの設定から行えます。")
                    if let eulaURL = URL(string: Constants.URLs.appleEULA) {
                        Link("利用許諾契約（EULA）", destination: eulaURL)
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

/// 購入ボタン
struct PurchaseButton: View {
    let label: String
    let isPurchasing: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(label)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isDisabled)
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
        .environment(StoreManager.shared)
        .modelContainer(.preview)
}
