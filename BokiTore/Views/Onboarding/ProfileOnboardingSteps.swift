import SwiftUI

// MARK: - ステップ0: 学習目的の選択（シングル選択）

/// オンボーディングの最初のステップ: ユーザーの学習目的を収集する
struct StudyPurposeStep: View {
    /// 選択された学習目的（親Viewが管理）
    @Binding var selectedPurpose: String

    /// 学習目的の選択肢一覧
    private let purposeOptions: [(id: String, label: String, icon: String)] = [
        ("job_hunting",    "就職活動",              "briefcase.fill"),
        ("career_up",      "キャリアアップ・昇進",   "chart.line.uptrend.xyaxis"),
        ("school_credits", "学校の授業・単位取得",    "graduationcap.fill"),
        ("hobby",          "趣味・教養",             "book.fill")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(Color.appPrimary)

            Text("簿記を学ぶ目的は？")
                .font(.title2)
                .fontWeight(.bold)

            Text("あなたに合った学習プランを提案します")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 選択肢カード（dailyGoalStepと同じ雰囲気）
            VStack(spacing: 12) {
                ForEach(purposeOptions, id: \.id) { option in
                    let isSelected = selectedPurpose == option.id
                    Button {
                        selectedPurpose = option.id
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .frame(width: 24)
                            Text(option.label)
                                .font(.headline)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        .padding()
                        .background(isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.appPrimary : Color(.separator),
                                        lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - ステップ1: 興味のある資格（マルチ選択）

/// オンボーディングの2番目のステップ: ユーザーの興味資格を収集する
struct InterestedCertsStep: View {
    /// 選択された資格のセット（親Viewが管理）
    @Binding var selectedCerts: Set<String>

    /// 資格の選択肢一覧
    private let certOptions: [(id: String, label: String)] = [
        ("fp",       "FP技能検定"),
        ("takken",   "宅建（宅地建物取引士）"),
        ("toeic",    "TOEIC・英語"),
        ("hisho",    "秘書検定"),
        ("mos",      "MOS（マイクロソフトオフィス）"),
        ("it_pass",  "ITパスポート"),
        ("none",     "特になし")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.bubble")
                .font(.system(size: 60))
                .foregroundStyle(Color.appSecondary)

            Text("他に興味のある資格は？")
                .font(.title2)
                .fontWeight(.bold)

            Text("関連するおすすめ情報をお届けします")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 資格チェックボックス一覧（複数選択可）
            VStack(spacing: 10) {
                ForEach(certOptions, id: \.id) { option in
                    let isSelected = selectedCerts.contains(option.id)
                    Button {
                        toggleCert(option.id)
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isSelected ? Color.appPrimary : Color(.separator))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.appPrimary : Color(.separator),
                                        lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    /// 資格の選択/解除を切り替える（「特になし」は排他的）
    private func toggleCert(_ certId: String) {
        if certId == "none" {
            // 「特になし」を選択 → 他を全解除
            selectedCerts = ["none"]
        } else {
            // 他の選択肢 → 「特になし」を解除
            selectedCerts.remove("none")
            if selectedCerts.contains(certId) {
                selectedCerts.remove(certId)
            } else {
                selectedCerts.insert(certId)
            }
        }
    }
}

// MARK: - プレビュー

#Preview("StudyPurposeStep") {
    StudyPurposeStep(selectedPurpose: .constant(""))
}

#Preview("InterestedCertsStep") {
    InterestedCertsStep(selectedCerts: .constant(["fp"]))
}
