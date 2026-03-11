import SwiftUI

/// 結果画面 — クイズ終了後の成績表示
struct QuizResultView: View {
    let viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // タイトル
                Text("結果発表")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // 正答数と正答率
                VStack(spacing: 8) {
                    Text("\(viewModel.session.correctCount) / \(viewModel.totalCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("正答率 \(Int(viewModel.session.accuracy * 100))%")
                        .font(.title2)
                        .foregroundStyle(viewModel.session.accuracy >= 0.8 ? Color.appSecondary : Color.appError)
                }

                // 所要時間
                HStack {
                    Image(systemName: "timer")
                    Text("所要時間: \(viewModel.formattedTotalTime)")
                }
                .font(.headline)
                .foregroundStyle(.secondary)

                // 間違えた問題リスト
                if !viewModel.session.incorrectQuestionIds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("間違えた問題")
                            .font(.headline)

                        ForEach(viewModel.incorrectQuestions, id: \.id) { question in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.appError)
                                Text(question.questionText)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // ボタン群
                VStack(spacing: 12) {
                    // 間違えた問題を復習
                    if !viewModel.incorrectQuestions.isEmpty {
                        NavigationLink {
                            QuizView(questions: viewModel.incorrectQuestions)
                        } label: {
                            Text("間違えた問題を復習")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // ホームに戻る
                    Button {
                        dismiss()
                    } label: {
                        Text("ホームに戻る")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            AdBannerPlaceholder()
        }
    }
}

#Preview {
    NavigationStack {
        QuizResultView(
            viewModel: QuizViewModel(questions: QuestionLoader.shared.allQuestions)
        )
    }
}
