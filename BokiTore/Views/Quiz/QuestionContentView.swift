import SwiftUI

/// 問題フォーマットに応じたViewを表示するルーター
/// QuizView から呼ばれ、フォーマットに応じた入力UIに振り分ける
struct QuestionContentView: View {
    let question: Question
    let viewModel: QuizViewModel

    var body: some View {
        switch question.effectiveFormat {
        case .multipleChoice:
            // 従来の4択（ChoiceButton再利用）
            MultipleChoiceContent(question: question, viewModel: viewModel)

        case .cbtJournalEntry:
            CBTEntryView(question: question, viewModel: viewModel)

        case .tAccountFill:
            TAccountFillView(question: question, viewModel: viewModel)

        case .subledgerSelect:
            SubledgerSelectView(question: question, viewModel: viewModel)

        case .theoryFill:
            TheoryFillView(question: question, viewModel: viewModel)
        }
    }
}

/// 従来の4択表示（ChoiceButtonをそのまま再利用）
private struct MultipleChoiceContent: View {
    let question: Question
    let viewModel: QuizViewModel

    var body: some View {
        ForEach(viewModel.shuffledChoices(for: question)) { choice in
            ChoiceButton(
                choice: choice,
                isSelected: viewModel.selectedAnswerId == choice.id,
                isCorrect: viewModel.showResult ? choice.id == question.correctAnswer : nil,
                isDisabled: viewModel.showResult
            ) {
                viewModel.submitAnswer(.multipleChoice(choiceId: choice.id))
            }
        }
    }
}

#Preview {
    ScrollView {
        QuestionContentView(
            question: QuestionLoader.shared.allQuestions.first ?? Question(
                id: "test", category: "journalEntry", subcategory: "test",
                difficulty: 1, questionType: "multipleChoice",
                questionText: "テスト問題",
                choices: [], correctAnswer: "", explanation: "テスト解説",
                tags: [], termDefinitions: nil, frequencyRank: nil,
                examSection: nil, format: nil, questionData: nil
            ),
            viewModel: QuizViewModel(questions: QuestionLoader.shared.allQuestions)
        )
        .padding()
    }
}
