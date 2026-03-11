import SwiftUI
import SwiftData

/// 問題画面 — 問題の表示と選択肢の選択
struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: QuizViewModel

    /// 指定された問題リストでクイズを開始
    init(questions: [Question]) {
        _viewModel = State(initialValue: QuizViewModel(questions: questions))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isCompleted {
                // 結果画面へ遷移
                QuizResultView(viewModel: viewModel)
            } else if let question = viewModel.currentQuestion {
                // 問題表示
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 進捗バーとタイマー
                            HStack {
                                ProgressView(value: viewModel.progress)
                                    .tint(.appPrimary)

                                // 経過時間の表示
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption)
                                    Text(viewModel.formattedElapsedTime)
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                .foregroundStyle(.secondary)
                            }

                            // 難易度バッジと正答状況
                            HStack {
                                DifficultyBadge(level: question.difficulty)
                                Spacer()
                                if viewModel.currentIndex > 0 {
                                    Text("\(viewModel.currentCorrectCount)/\(viewModel.currentIndex)問正解")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // 問題文
                            Text(question.questionText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .padding(.vertical)

                            // 選択肢
                            ForEach(question.choices) { choice in
                                ChoiceButton(
                                    choice: choice,
                                    isSelected: viewModel.selectedAnswer == choice.id,
                                    isCorrect: viewModel.showResult ? choice.id == question.correctAnswer : nil,
                                    isDisabled: viewModel.showResult
                                ) {
                                    viewModel.selectAnswer(choice.id)
                                }
                            }

                            // 解説表示（解答後）
                            if viewModel.showResult {
                                ExplanationView(
                                    isCorrect: viewModel.isCurrentAnswerCorrect,
                                    explanation: question.explanation,
                                    correctChoice: question.choices.first { $0.id == question.correctAnswer }
                                )

                                // 次の問題ボタン
                                Button {
                                    viewModel.nextQuestion(modelContext: modelContext)
                                } label: {
                                    Text(viewModel.isLastQuestion ? "結果を見る" : "次の問題 →")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appPrimary)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .id("nextButton")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.showResult) {
                        // 解答後に「次の問題」ボタンまで自動スクロール
                        if viewModel.showResult {
                            withAnimation {
                                proxy.scrollTo("nextButton", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // バナー広告（プレミアム会員は非表示）
            if !StoreManager.shared.isPremium {
                AdBannerPlaceholder()
            }
        }
        .navigationTitle("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 難易度バッジ
struct DifficultyBadge: View {
    let level: Int

    /// 難易度に応じたラベルと色
    private var config: (text: String, color: Color) {
        switch level {
        case 1: return ("基本", .appSecondary)
        case 2: return ("標準", .orange)
        case 3: return ("応用", .appError)
        default: return ("--", .gray)
        }
    }

    var body: some View {
        Text(config.text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(config.color.opacity(0.15))
            .foregroundStyle(config.color)
            .clipShape(Capsule())
    }
}

/// 選択肢ボタン
struct ChoiceButton: View {
    let choice: Choice
    let isSelected: Bool
    let isCorrect: Bool?   // nil = まだ解答していない
    let isDisabled: Bool
    let action: () -> Void

    /// ボタンの背景色を決定
    private var backgroundColor: Color {
        guard let isCorrect else {
            return isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground)
        }
        if isCorrect && isSelected {
            return Color.appSecondary.opacity(0.15)
        } else if !isCorrect && isSelected {
            return Color.appError.opacity(0.15)
        } else if isCorrect {
            // 正解の選択肢は常に緑（未選択でも）
            return Color.appSecondary.opacity(0.08)
        }
        return Color(.systemBackground)
    }

    /// ボタンの枠線色
    private var borderColor: Color {
        guard let isCorrect else {
            return isSelected ? .appPrimary : Color(.separator)
        }
        if isCorrect {
            return .appSecondary
        } else if isSelected {
            return .appError
        }
        return Color(.separator)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(choice.id.uppercased()).")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading) {
                        Text("(借) \(choice.debit)")
                        Text("(貸) \(choice.credit)")
                    }
                    .font(.body)
                    Spacer()

                    // 解答後のアイコン表示
                    if let isCorrect {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appSecondary)
                        } else if isSelected {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.appError)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(isDisabled)
        .foregroundStyle(.primary)
    }
}

#Preview {
    NavigationStack {
        QuizView(questions: QuestionLoader.shared.allQuestions)
    }
    .modelContainer(for: [UserProgress.self, StudyStreak.self], inMemory: true)
}
