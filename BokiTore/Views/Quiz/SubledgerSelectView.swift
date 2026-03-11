import SwiftUI

/// 補助簿選択 — 取引ごとに該当する補助簿をチェックボックスで選択
/// 実際の簿記3級第2問⑵-Aに対応する出題形式
struct SubledgerSelectView: View {
    let question: Question
    let viewModel: QuizViewModel
    /// 取引ID → 選択した補助簿のSet
    @State private var selections: [String: Set<String>] = [:]

    /// 補助簿選択データ
    private var data: SubledgerSelectData? {
        guard case .subledgerSelect(let d) = question.questionData else { return nil }
        return d
    }

    var body: some View {
        if viewModel.showResult {
            EmptyView()
        } else if let data {
            VStack(alignment: .leading, spacing: 16) {
                // 補助簿オプションのヘッダー（凡例）
                SubledgerLegend(options: data.subledgerOptions)

                // 各取引の選択行
                ForEach(data.transactions) { transaction in
                    TransactionRow(
                        transaction: transaction,
                        subledgerOptions: data.subledgerOptions,
                        selected: binding(for: transaction.id)
                    )
                }

                // 解答ボタン
                Button {
                    viewModel.submitAnswer(.subledgerSelect(selections: selections))
                } label: {
                    Text("解答する")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allAnswered(data: data) ? Color.appPrimary : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!allAnswered(data: data))
            }
        }
    }

    /// 全取引に1つ以上のチェックがあるか
    private func allAnswered(data: SubledgerSelectData) -> Bool {
        data.transactions.allSatisfy { tx in
            !(selections[tx.id]?.isEmpty ?? true)
        }
    }

    /// 取引IDに対するSet<String>のBinding
    private func binding(for txId: String) -> Binding<Set<String>> {
        Binding(
            get: { selections[txId] ?? [] },
            set: { selections[txId] = $0 }
        )
    }
}

// MARK: - サブコンポーネント

/// 補助簿の凡例（ヘッダー行）
private struct SubledgerLegend: View {
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("該当する補助簿をすべて選択してください")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 補助簿名を横並び表示
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// 1取引分の選択行（取引説明 + チェックボックスグリッド）
private struct TransactionRow: View {
    let transaction: SubledgerTransaction
    let subledgerOptions: [String]
    @Binding var selected: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 取引の説明文
            Text(transaction.description)
                .font(.subheadline)
                .padding(.horizontal, 4)

            // チェックボックスグリッド（3列）
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 6
            ) {
                ForEach(subledgerOptions, id: \.self) { option in
                    SubledgerCheckbox(
                        label: option,
                        isChecked: selected.contains(option)
                    ) {
                        if selected.contains(option) {
                            selected.remove(option)
                        } else {
                            selected.insert(option)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// 補助簿チェックボックス
private struct SubledgerCheckbox: View {
    let label: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? Color.appPrimary : Color.secondary)
                    .font(.caption)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(isChecked ? Color.appPrimary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        SubledgerSelectView(
            question: Question(
                id: "sub_test", category: "補助簿", subcategory: "補助簿選択",
                difficulty: 2, questionType: "subledger_select",
                questionText: "次の各取引について、記入が必要な補助簿をすべて選びなさい。",
                choices: [], correctAnswer: "", explanation: "テスト解説",
                tags: [], termDefinitions: nil, frequencyRank: "A",
                examSection: "第2問⑵-A", format: .subledgerSelect,
                questionData: .subledgerSelect(SubledgerSelectData(
                    type: "subledgerSelect",
                    transactions: [
                        SubledgerTransaction(
                            id: "tx_1",
                            description: "① 商品100,000円を掛けで仕入れた。",
                            correctSubledgers: ["仕入帳", "買掛金元帳"]
                        ),
                        SubledgerTransaction(
                            id: "tx_2",
                            description: "② 備品200,000円を小切手を振り出して購入した。",
                            correctSubledgers: ["当座預金出納帳"]
                        ),
                        SubledgerTransaction(
                            id: "tx_3",
                            description: "③ 得意先に商品150,000円を掛けで売り上げた。",
                            correctSubledgers: ["売上帳", "売掛金元帳"]
                        )
                    ],
                    subledgerOptions: [
                        "現金出納帳", "当座預金出納帳", "仕入帳",
                        "売上帳", "買掛金元帳", "売掛金元帳",
                        "受取手形記入帳", "支払手形記入帳", "商品有高帳"
                    ]
                ))
            ),
            viewModel: QuizViewModel(questions: [])
        )
        .padding()
    }
}
