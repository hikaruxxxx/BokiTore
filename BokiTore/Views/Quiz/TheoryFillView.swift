import SwiftUI

/// 理論穴埋め — 文章中の空欄にプルダウンから語句を選択
/// 簿記3級第2問⑵-Bに対応する出題形式
struct TheoryFillView: View {
    let question: Question
    let viewModel: QuizViewModel
    /// 空欄ID → 選択した語句
    @State private var blankAnswers: [String: String] = [:]

    /// 理論穴埋めデータ
    private var data: TheoryFillData? {
        guard case .theoryFill(let d) = question.questionData else { return nil }
        return d
    }

    var body: some View {
        if viewModel.showResult {
            EmptyView()
        } else if let data {
            VStack(alignment: .leading, spacing: 16) {
                // 指示テキスト
                Text("次の文章の空欄に当てはまる語句を選びなさい。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 穴埋め文章
                PassageView(
                    passage: data.passage,
                    blanks: data.blanks,
                    blankAnswers: $blankAnswers
                )
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // 解答ボタン
                Button {
                    viewModel.submitAnswer(.theoryFill(answers: blankAnswers))
                } label: {
                    Text("解答する")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allBlanksAnswered(data: data) ? Color.appPrimary : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!allBlanksAnswered(data: data))
            }
        }
    }

    /// 全空欄が回答済みか
    private func allBlanksAnswered(data: TheoryFillData) -> Bool {
        data.blanks.allSatisfy { !(blankAnswers[$0.id]?.isEmpty ?? true) }
    }
}

// MARK: - 文章表示（テキスト + インラインプルダウン）

/// 穴埋め文章を段落ごとに分割して表示
private struct PassageView: View {
    let passage: String
    let blanks: [TheoryBlank]
    @Binding var blankAnswers: [String: String]

    /// 文章を "[blank_X]" で分割してセグメント化
    private var segments: [PassageSegment] {
        parsePassage(passage, blanks: blanks)
    }

    var body: some View {
        // FlowLayout的に表示（VStackで折り返し）
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text):
                    Text(text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                case .blank(let blank):
                    InlineBlankPicker(
                        blank: blank,
                        answer: Binding(
                            get: { blankAnswers[blank.id] ?? "" },
                            set: { blankAnswers[blank.id] = $0 }
                        )
                    )
                }
            }
        }
    }
}

/// 文章のセグメント（テキストまたは空欄）
private enum PassageSegment {
    case text(String)
    case blank(TheoryBlank)
}

/// passage 文字列を "[blank_X]" で分割
private func parsePassage(_ passage: String, blanks: [TheoryBlank]) -> [PassageSegment] {
    var segments: [PassageSegment] = []
    var remaining = passage

    // 空欄IDをマップ化
    let blankMap = Dictionary(uniqueKeysWithValues: blanks.map { ($0.id, $0) })

    // "[blank_X]" パターンで分割
    while let range = remaining.range(of: #"\[blank_\d+\]"#, options: .regularExpression) {
        // 空欄の前のテキスト
        let before = String(remaining[remaining.startIndex..<range.lowerBound])
        if !before.isEmpty {
            segments.append(.text(before))
        }

        // 空欄IDを抽出（"[" と "]" を除去）
        let blankId = String(remaining[range]).dropFirst().dropLast()
        if let blank = blankMap[String(blankId)] {
            segments.append(.blank(blank))
        }

        remaining = String(remaining[range.upperBound...])
    }

    // 残りのテキスト
    if !remaining.isEmpty {
        segments.append(.text(remaining))
    }

    return segments
}

/// インラインの空欄プルダウン
private struct InlineBlankPicker: View {
    let blank: TheoryBlank
    @Binding var answer: String

    var body: some View {
        HStack(spacing: 4) {
            // 空欄番号ラベル
            Text("[\(blank.id)]")
                .font(.caption2)
                .foregroundStyle(Color.appPrimary)
                .fontWeight(.bold)

            // プルダウン選択
            Picker("", selection: $answer) {
                Text("選択").tag("")
                ForEach(blank.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(answer.isEmpty ? .secondary : .appPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(answer.isEmpty ? Color.gray.opacity(0.3) : Color.appPrimary, lineWidth: 1)
            )
        }
    }
}

#Preview {
    ScrollView {
        TheoryFillView(
            question: Question(
                id: "theory_test", category: "理論", subcategory: "帳簿組織",
                difficulty: 2, questionType: "theory_fill",
                questionText: "次の文章の空欄に当てはまる語句を選びなさい。",
                choices: [], correctAnswer: "", explanation: "テスト解説",
                tags: [], termDefinitions: nil, frequencyRank: "A",
                examSection: "第2問⑵-B", format: .theoryFill,
                questionData: .theoryFill(TheoryFillData(
                    type: "theoryFill",
                    passage: "帳簿は[blank_1]と[blank_2]に分けられる。[blank_1]には仕訳帳と総勘定元帳が含まれ、[blank_2]には現金出納帳や売掛金元帳などが含まれる。仕訳帳から総勘定元帳への記入を[blank_3]という。",
                    blanks: [
                        TheoryBlank(id: "blank_1", options: ["主要簿", "補助簿", "特殊仕訳帳", "普通仕訳帳"], correctAnswer: "主要簿"),
                        TheoryBlank(id: "blank_2", options: ["補助簿", "主要簿", "伝票", "精算表"], correctAnswer: "補助簿"),
                        TheoryBlank(id: "blank_3", options: ["転記", "仕訳", "決算", "締切"], correctAnswer: "転記")
                    ]
                ))
            ),
            viewModel: QuizViewModel(questions: [])
        )
        .padding()
    }
}
