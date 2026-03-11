import SwiftUI
import SwiftData

/// 問題画面 — 問題の表示と選択肢の選択
struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: QuizViewModel
    @State private var showQuitAlert = false
    /// 診断モード（trueの場合、完了後にDiagnosisResultViewを表示）
    private let isDiagnosisMode: Bool

    /// 指定された問題リストでクイズを開始
    init(questions: [Question], isDiagnosisMode: Bool = false) {
        _viewModel = State(initialValue: QuizViewModel(questions: questions))
        self.isDiagnosisMode = isDiagnosisMode
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isCompleted {
                // 結果画面へ遷移（診断モードは専用画面）
                if isDiagnosisMode {
                    DiagnosisResultView(viewModel: viewModel)
                } else {
                    QuizResultView(viewModel: viewModel)
                }
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

                            // コンボインジケーター（3連続正解以上で表示）
                            ComboIndicatorView(count: viewModel.consecutiveCorrectRun)

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

                            // 選択肢（シャッフル済み — 正解が常に同じ位置にならないように）
                            // フォーマット別の問題表示（multipleChoiceは従来のChoiceButton）
                            QuestionContentView(question: question, viewModel: viewModel)

                            // 解説表示（解答後）
                            if viewModel.showResult {
                                // 励ましメッセージ
                                MotivationMessageView(
                                    isCorrect: viewModel.isCurrentAnswerCorrect,
                                    comboCount: viewModel.consecutiveCorrectRun
                                )

                                ExplanationView(
                                    isCorrect: viewModel.isCurrentAnswerCorrect,
                                    question: question,
                                    explanation: question.explanation,
                                    correctChoice: question.choices.first { $0.id == question.correctAnswer },
                                    termDefinitions: question.termDefinitions
                                )

                                // ブックマークボタン
                                BookmarkButton(
                                    questionId: question.id,
                                    wasCorrect: viewModel.isCurrentAnswerCorrect,
                                    category: question.category
                                )

                                // 次の問題ボタン
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.nextQuestion(modelContext: modelContext)
                                    }
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
            if !storeManager.isPremium {
                AdBannerPlaceholder()
            }
        }
        .navigationTitle("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!viewModel.isCompleted)
        .toolbar {
            if !viewModel.isCompleted {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showQuitAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                    }
                }
            }
        }
        .alert("クイズを中断しますか？", isPresented: $showQuitAlert) {
            Button("続ける", role: .cancel) { }
            Button("中断する", role: .destructive) { dismiss() }
        } message: {
            Text("現在の進捗は保存されません。")
        }
    }
}

#Preview {
    NavigationStack {
        QuizView(questions: QuestionLoader.shared.allQuestions)
    }
    .environment(StoreManager.shared)
    .modelContainer(for: [UserProgress.self, StudyStreak.self], inMemory: true)
}
