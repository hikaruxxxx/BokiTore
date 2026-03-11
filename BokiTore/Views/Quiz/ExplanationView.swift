import SwiftUI

/// 解説表示ビュー — 正解/不正解の結果と解説を表示
struct ExplanationView: View {
    let isCorrect: Bool
    /// 問題データ（フォーマット別の正解表示に使用）
    let question: Question
    let explanation: String
    /// 正解の選択肢（multipleChoice用 — 他フォーマットではnil）
    let correctChoice: Choice?
    /// 用語解説リスト（問題に termDefinitions がある場合に表示）
    var termDefinitions: [TermDefinition]?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 正解/不正解の表示
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(isCorrect ? Color.appSecondary : Color.appError)

                Text(isCorrect ? "正解！" : "不正解")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(isCorrect ? Color.appSecondary : Color.appError)
            }

            // フォーマット別の正解表示
            CorrectAnswerSection(question: question, correctChoice: correctChoice)

            // 解説テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text("解説")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(explanation)
                    .font(.callout)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 用語解説セクション（termDefinitions がある場合のみ表示）
            if let terms = termDefinitions, !terms.isEmpty {
                TermDefinitionsSection(terms: terms)
            }
        }
    }
}

// MARK: - フォーマット別の正解表示

/// フォーマットに応じた正解表示セクション
private struct CorrectAnswerSection: View {
    let question: Question
    let correctChoice: Choice?

    var body: some View {
        switch question.effectiveFormat {
        case .multipleChoice:
            // 従来の4択: 正しい仕訳の表示
            if let correctChoice {
                CorrectChoiceCard(correctChoice: correctChoice)
            }

        case .cbtJournalEntry:
            // CBT仕訳: 正解の仕訳行を表示
            if case .journalEntry(let data) = question.questionData {
                CorrectJournalEntryCard(entries: data.correctEntries)
            }

        case .tAccountFill:
            // T勘定: 正解値を一覧表示
            if case .tAccountFill(let data) = question.questionData {
                CorrectTAccountCard(blanks: data.blanks)
            }

        case .subledgerSelect:
            // 補助簿: 各取引の正解補助簿を表示
            if case .subledgerSelect(let data) = question.questionData {
                CorrectSubledgerCard(transactions: data.transactions)
            }

        case .theoryFill:
            // 理論穴埋め: 正解語句を一覧表示
            if case .theoryFill(let data) = question.questionData {
                CorrectTheoryCard(blanks: data.blanks)
            }
        }
    }
}

/// 従来の4択正解カード
private struct CorrectChoiceCard: View {
    let correctChoice: Choice

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("正しい仕訳:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("(借) \(correctChoice.debit)")
                .font(.body)
                .fontWeight(.medium)
            Text("(貸) \(correctChoice.credit)")
                .font(.body)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// CBT仕訳入力の正解カード
private struct CorrectJournalEntryCard: View {
    let entries: [JournalLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("正しい仕訳:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(entries.filter { $0.side == "debit" }, id: \.comparisonKey) { entry in
                Text("(借) \(entry.account) \(entry.amount.formatted())")
                    .font(.body)
                    .fontWeight(.medium)
            }
            ForEach(entries.filter { $0.side == "credit" }, id: \.comparisonKey) { entry in
                Text("(貸) \(entry.account) \(entry.amount.formatted())")
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// T勘定空欄の正解カード
private struct CorrectTAccountCard: View {
    let blanks: [TAccountBlank]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("正解:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(blanks) { blank in
                HStack {
                    Text(blank.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(blank.correctAnswer)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// 補助簿選択の正解カード
private struct CorrectSubledgerCard: View {
    let transactions: [SubledgerTransaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("正解の補助簿:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(transactions) { tx in
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(tx.correctSubledgers.joined(separator: "、"))
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// 理論穴埋めの正解カード
private struct CorrectTheoryCard: View {
    let blanks: [TheoryBlank]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("正解:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(blanks) { blank in
                HStack {
                    Text(blank.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(blank.correctAnswer)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 用語解説セクション

/// 用語解説セクション — 問題に登場する専門用語を初心者向けに表示
private struct TermDefinitionsSection: View {
    let terms: [TermDefinition]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 折りたたみヘッダー
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "book.closed")
                        .font(.subheadline)
                    Text("用語解説（\(terms.count)件）")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(Color.appPrimary)
            }
            .buttonStyle(.plain)

            // 用語リスト（展開時のみ表示）
            if isExpanded {
                ForEach(terms, id: \.term) { term in
                    TermDefinitionCard(term: term)
                }
            }
        }
        .padding()
        .background(Color.appPrimary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// 個別の用語カード
private struct TermDefinitionCard: View {
    let term: TermDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 用語名と分類
            HStack(spacing: 6) {
                Text(term.term)
                    .font(.callout)
                    .fontWeight(.bold)
                Text(term.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.2))
                    .foregroundStyle(categoryColor)
                    .clipShape(Capsule())
            }

            // 定義
            Text(term.definition)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 身近な例え（ある場合のみ）
            if let example = term.realWorldExample {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(example)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// 分類に応じた色分け
    private var categoryColor: Color {
        switch term.category {
        case "資産": return .blue
        case "負債": return .red
        case "純資産": return .purple
        case "収益": return .green
        case "費用": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview用のサンプルQuestion

private let previewQuestion = Question(
    id: "preview_001",
    category: "journalEntry",
    subcategory: "sales",
    difficulty: 1,
    questionType: "multipleChoice",
    questionText: "商品100,000円を掛けで売り上げた。",
    choices: [
        Choice(id: "a", debit: "売掛金 100,000", credit: "売上 100,000"),
        Choice(id: "b", debit: "売上 100,000", credit: "売掛金 100,000")
    ],
    correctAnswer: "a",
    explanation: "掛けでの売上は、借方に売掛金（資産の増加）、貸方に売上（収益の発生）を記入します。",
    tags: ["売掛金", "売上"],
    termDefinitions: [
        TermDefinition(
            term: "売掛金",
            category: "資産",
            definition: "商品を掛けで売った場合に、後から代金を受け取る権利のこと。",
            realWorldExample: "ツケで食事をした時の、お店側の「後で払ってもらう権利」"
        ),
        TermDefinition(
            term: "売上",
            category: "収益",
            definition: "商品を販売して得た収入のこと。",
            realWorldExample: nil
        )
    ],
    frequencyRank: "A",
    examSection: "第1問",
    format: nil,
    questionData: nil
)

#Preview("解説+用語解説") {
    ScrollView {
        ExplanationView(
            isCorrect: false,
            question: previewQuestion,
            explanation: previewQuestion.explanation,
            correctChoice: Choice(id: "a", debit: "売掛金 100,000", credit: "売上 100,000"),
            termDefinitions: previewQuestion.termDefinitions
        )
        .padding()
    }
}

#Preview("解説のみ") {
    ExplanationView(
        isCorrect: true,
        question: previewQuestion,
        explanation: previewQuestion.explanation,
        correctChoice: Choice(id: "a", debit: "売掛金 100,000", credit: "売上 100,000")
    )
    .padding()
}
