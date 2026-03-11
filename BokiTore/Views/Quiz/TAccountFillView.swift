import SwiftUI

/// T勘定空欄補充 — T字勘定の視覚表示 + 空欄入力
/// 勘定科目のT字フォーマットを画面上に再現し、空欄をPicker/TextFieldで埋める
struct TAccountFillView: View {
    let question: Question
    let viewModel: QuizViewModel
    @State private var blankAnswers: [String: String] = [:]

    /// T勘定データ
    private var data: TAccountFillData? {
        guard case .tAccountFill(let d) = question.questionData else { return nil }
        return d
    }

    var body: some View {
        if viewModel.showResult {
            EmptyView()
        } else if let data {
            VStack(spacing: 16) {
                // T勘定ヘッダー（勘定科目名）
                Text(data.accountName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // T字レイアウト
                HStack(alignment: .top, spacing: 0) {
                    // 借方（左側）
                    VStack(alignment: .leading, spacing: 6) {
                        Text("借方")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        ForEach(debitItems(data: data)) { item in
                            TAccountItemRow(item: item, blankAnswers: $blankAnswers, data: data)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)

                    // 仕切り線
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2)

                    // 貸方（右側）
                    VStack(alignment: .leading, spacing: 6) {
                        Text("貸方")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        ForEach(creditItems(data: data)) { item in
                            TAccountItemRow(item: item, blankAnswers: $blankAnswers, data: data)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // 解答ボタン
                Button {
                    viewModel.submitAnswer(.tAccountFill(answers: blankAnswers))
                } label: {
                    Text("解答する")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allBlanksAnswered ? Color.appPrimary : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!allBlanksAnswered)
            }
        }
    }

    /// 全空欄が回答済みか
    private var allBlanksAnswered: Bool {
        guard let data else { return false }
        return data.blanks.allSatisfy { !(blankAnswers[$0.id]?.isEmpty ?? true) }
    }

    /// 借方側のアイテム一覧（記入済み + 空欄）
    private func debitItems(data: TAccountFillData) -> [TAccountItem] {
        var items: [TAccountItem] = []
        // 記入済みエントリ
        for entry in data.prefilledEntries where entry.side == "debit" {
            items.append(.prefilled(entry))
        }
        // 空欄
        for blank in data.blanks where blank.side == "debit" {
            items.append(.blank(blank))
        }
        return items
    }

    /// 貸方側のアイテム一覧（記入済み + 空欄）
    private func creditItems(data: TAccountFillData) -> [TAccountItem] {
        var items: [TAccountItem] = []
        for entry in data.prefilledEntries where entry.side == "credit" {
            items.append(.prefilled(entry))
        }
        for blank in data.blanks where blank.side == "credit" {
            items.append(.blank(blank))
        }
        return items
    }
}

// MARK: - T勘定アイテム（記入済み or 空欄）

/// T勘定の1行（記入済みまたは空欄）
private enum TAccountItem: Identifiable {
    case prefilled(TAccountEntry)
    case blank(TAccountBlank)

    var id: String {
        switch self {
        case .prefilled(let entry): return "pre_\(entry.id)"
        case .blank(let blank): return blank.id
        }
    }
}

/// T勘定1行の表示
private struct TAccountItemRow: View {
    let item: TAccountItem
    @Binding var blankAnswers: [String: String]
    let data: TAccountFillData

    var body: some View {
        switch item {
        case .prefilled(let entry):
            // 記入済み: 日付 + 摘要 + 金額
            HStack {
                if let date = entry.date {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .leading)
                }
                Text(entry.description)
                    .font(.caption)
                Spacer()
                Text(entry.amount.formatted())
                    .font(.caption)
                    .monospacedDigit()
            }

        case .blank(let blank):
            // 空欄: 入力タイプに応じたUI
            HStack {
                Text("[\(blank.id)]")
                    .font(.caption2)
                    .foregroundStyle(Color.appPrimary)
                BlankInputView(blank: blank, answer: binding(for: blank.id), data: data)
            }
        }
    }

    private func binding(for blankId: String) -> Binding<String> {
        Binding(
            get: { blankAnswers[blankId] ?? "" },
            set: { blankAnswers[blankId] = $0 }
        )
    }
}

/// 空欄タイプに応じた入力UI
private struct BlankInputView: View {
    let blank: TAccountBlank
    @Binding var answer: String
    let data: TAccountFillData

    var body: some View {
        switch blank.answerType {
        case "amount":
            // 金額入力
            TextField("金額", text: $answer)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.caption)
                .padding(4)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))

        case "account":
            // 勘定科目プルダウン（記入済みの科目名を候補にする）
            let options = Set(data.prefilledEntries.map { $0.description }
                + data.blanks.filter { $0.answerType == "account" }.map { $0.correctAnswer })
            Picker("", selection: $answer) {
                Text("選択").tag("")
                ForEach(Array(options).sorted(), id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(.caption)

        default:
            // 摘要プルダウン（"次期繰越"等の候補）
            let descriptions = ["次期繰越", "前期繰越", "損益", "仕入", "売上", "減価償却費"]
            Picker("", selection: $answer) {
                Text("選択").tag("")
                ForEach(descriptions, id: \.self) { desc in
                    Text(desc).tag(desc)
                }
            }
            .pickerStyle(.menu)
            .font(.caption)
        }
    }
}

#Preview {
    ScrollView {
        TAccountFillView(
            question: Question(
                id: "t_test", category: "勘定記入", subcategory: "固定資産台帳",
                difficulty: 2, questionType: "t_account_fill",
                questionText: "次のT勘定の空欄を埋めなさい。",
                choices: [], correctAnswer: "", explanation: "テスト解説",
                tags: [], termDefinitions: nil, frequencyRank: "A",
                examSection: "第2問⑴", format: .tAccountFill,
                questionData: .tAccountFill(TAccountFillData(
                    type: "tAccountFill",
                    accountName: "備品",
                    prefilledEntries: [
                        TAccountEntry(side: "debit", description: "前期繰越", amount: 300000, date: "4/1"),
                        TAccountEntry(side: "debit", description: "当座預金", amount: 200000, date: "7/1")
                    ],
                    blanks: [
                        TAccountBlank(id: "blank_1", side: "credit", position: 0, answerType: "description", correctAnswer: "次期繰越"),
                        TAccountBlank(id: "blank_2", side: "credit", position: 0, answerType: "amount", correctAnswer: "500000")
                    ]
                ))
            ),
            viewModel: QuizViewModel(questions: [])
        )
        .padding()
    }
}
