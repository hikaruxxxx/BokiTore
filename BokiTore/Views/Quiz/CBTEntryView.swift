import SwiftUI

/// CBT仕訳入力 — 勘定科目プルダウン + 金額入力で仕訳を構成
/// 実際のCBT試験に近い操作感を再現する
struct CBTEntryView: View {
    let question: Question
    let viewModel: QuizViewModel
    @State private var debitEntries: [EntryRow] = [EntryRow()]
    @State private var creditEntries: [EntryRow] = [EntryRow()]

    /// 勘定科目候補リスト（questionDataから取得）
    private var accountCandidates: [String] {
        guard case .journalEntry(let data) = question.questionData else { return [] }
        return data.accountCandidates
    }

    var body: some View {
        if viewModel.showResult {
            // 解答後: 結果表示のみ（入力UIは非表示）
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // 借方セクション
                SectionHeader(title: "借方（デビット）", color: .blue)
                ForEach(debitEntries.indices, id: \.self) { index in
                    EntryRowView(
                        entry: $debitEntries[index],
                        candidates: accountCandidates
                    )
                }
                if debitEntries.count < 3 {
                    AddRowButton { debitEntries.append(EntryRow()) }
                }

                Divider()

                // 貸方セクション
                SectionHeader(title: "貸方（クレジット）", color: .red)
                ForEach(creditEntries.indices, id: \.self) { index in
                    EntryRowView(
                        entry: $creditEntries[index],
                        candidates: accountCandidates
                    )
                }
                if creditEntries.count < 3 {
                    AddRowButton { creditEntries.append(EntryRow()) }
                }

                // 借貸一致チェック表示
                BalanceIndicator(
                    debitTotal: debitEntries.reduce(0) { $0 + ($1.amountValue) },
                    creditTotal: creditEntries.reduce(0) { $0 + ($1.amountValue) }
                )

                // 解答ボタン
                Button {
                    submitJournalEntry()
                } label: {
                    Text("解答する")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.appPrimary : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit)
            }
        }
    }

    /// 解答可能か（最低1つの借方と貸方が入力されている）
    private var canSubmit: Bool {
        let hasDebit = debitEntries.contains { !$0.account.isEmpty && $0.amountValue > 0 }
        let hasCredit = creditEntries.contains { !$0.account.isEmpty && $0.amountValue > 0 }
        return hasDebit && hasCredit
    }

    /// 仕訳入力を UserAnswer に変換して提出
    private func submitJournalEntry() {
        var entries: [JournalLine] = []
        for row in debitEntries where !row.account.isEmpty && row.amountValue > 0 {
            entries.append(JournalLine(side: "debit", account: row.account, amount: row.amountValue))
        }
        for row in creditEntries where !row.account.isEmpty && row.amountValue > 0 {
            entries.append(JournalLine(side: "credit", account: row.account, amount: row.amountValue))
        }
        viewModel.submitAnswer(.journalEntry(entries: entries))
    }
}

// MARK: - サブコンポーネント

/// 仕訳1行の入力状態
private struct EntryRow {
    var account: String = ""
    var amountText: String = ""

    /// 金額を数値に変換（無効な値は0）
    var amountValue: Int {
        Int(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
}

/// セクションヘッダー（借方/貸方）
private struct SectionHeader: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

/// 仕訳1行の入力UI
private struct EntryRowView: View {
    @Binding var entry: EntryRow
    let candidates: [String]

    var body: some View {
        HStack(spacing: 8) {
            // 勘定科目プルダウン
            Picker("勘定科目", selection: $entry.account) {
                Text("選択してください").tag("")
                ForEach(candidates, id: \.self) { candidate in
                    Text(candidate).tag(candidate)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 金額入力
            TextField("金額", text: $entry.amountText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// 行追加ボタン
private struct AddRowButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle")
                Text("行を追加")
                    .font(.caption)
            }
            .foregroundStyle(Color.appPrimary)
        }
    }
}

/// 借貸バランス表示
private struct BalanceIndicator: View {
    let debitTotal: Int
    let creditTotal: Int

    private var isBalanced: Bool { debitTotal == creditTotal && debitTotal > 0 }

    var body: some View {
        HStack {
            Text("借方合計: \(debitTotal.formatted())")
                .font(.caption)
            Spacer()
            Image(systemName: isBalanced ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(isBalanced ? .green : .orange)
                .font(.caption)
            Spacer()
            Text("貸方合計: \(creditTotal.formatted())")
                .font(.caption)
        }
        .padding(8)
        .background(isBalanced ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        CBTEntryView(
            question: Question(
                id: "cbt_test", category: "journalEntry", subcategory: "sales",
                difficulty: 2, questionType: "cbt_journal_entry",
                questionText: "商品100,000円を掛けで売り上げた。",
                choices: [], correctAnswer: "", explanation: "テスト解説",
                tags: [], termDefinitions: nil, frequencyRank: "A",
                examSection: "第1問", format: .cbtJournalEntry,
                questionData: .journalEntry(JournalEntryData(
                    type: "journalEntry",
                    accountCandidates: ["売掛金", "売上", "仕入", "買掛金", "現金", "未収入金"],
                    correctEntries: [
                        JournalLine(side: "debit", account: "売掛金", amount: 100000),
                        JournalLine(side: "credit", account: "売上", amount: 100000)
                    ]
                ))
            ),
            viewModel: QuizViewModel(questions: [])
        )
        .padding()
    }
}
