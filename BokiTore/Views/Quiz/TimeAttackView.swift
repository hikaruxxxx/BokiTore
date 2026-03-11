import SwiftUI
import SwiftData

/// タイムアタックモード画面
/// 60秒のカウントダウンで問題を解く
struct TimeAttackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel = TimeAttackViewModel()
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 0) {
            if !hasStarted {
                // スタート前の画面
                startScreen
            } else if viewModel.isFinished {
                // 結果画面
                resultScreen
            } else {
                // ゲーム中
                gameScreen
            }

            // バナー広告
            if !storeManager.isPremium {
                AdBannerPlaceholder()
            }
        }
        .navigationTitle("タイムアタック")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(hasStarted && !viewModel.isFinished)
    }

    // MARK: - スタート画面

    private var startScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("タイムアタック")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("60秒で何問正解できるか挑戦!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.start()
                hasStarted = true
            } label: {
                Text("スタート")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - ゲーム中

    private var gameScreen: some View {
        VStack(spacing: 16) {
            // タイマーとスコア
            HStack {
                // 残り時間
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundStyle(viewModel.remainingTime <= 10 ? .red : .orange)
                    Text(viewModel.formattedRemainingTime)
                        .font(.title)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(viewModel.remainingTime <= 10 ? .red : .primary)
                }

                Spacer()

                // スコア
                VStack(alignment: .trailing) {
                    Text("\(viewModel.correctCount)問正解")
                        .font(.headline)
                        .foregroundStyle(Color.appSecondary)
                    Text("\(viewModel.answeredCount)問解答")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // プログレスバー（残り時間）
            ProgressView(value: Double(viewModel.remainingTime), total: Double(Constants.Gamification.timeAttackDuration))
                .tint(viewModel.remainingTime <= 10 ? .red : .orange)
                .padding(.horizontal)

            // 問題表示
            if let question = viewModel.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 問題文
                        Text(question.questionText)
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding(.horizontal)

                        // 選択肢（シンプル版）
                        ForEach(question.choices) { choice in
                            Button {
                                viewModel.selectAnswer(choice.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("(借) \(choice.debit)")
                                        Text("(貸) \(choice.credit)")
                                    }
                                    .font(.body)
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(choiceBackground(for: choice.id))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(choiceBorder(for: choice.id), lineWidth: 1.5)
                                )
                            }
                            .disabled(viewModel.showFlash)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    /// 選択肢の背景色
    private func choiceBackground(for choiceId: String) -> Color {
        guard viewModel.showFlash, viewModel.selectedAnswer == choiceId else {
            return Color(.systemBackground)
        }
        return viewModel.lastAnswerCorrect ? Color.appSecondary.opacity(0.2) : Color.appError.opacity(0.2)
    }

    /// 選択肢の枠線色
    private func choiceBorder(for choiceId: String) -> Color {
        guard viewModel.showFlash, viewModel.selectedAnswer == choiceId else {
            return Color(.separator)
        }
        return viewModel.lastAnswerCorrect ? .appSecondary : .appError
    }

    // MARK: - 結果画面

    private var resultScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("タイムアップ!")
                .font(.largeTitle)
                .fontWeight(.bold)

            // スコア表示
            VStack(spacing: 8) {
                Text("\(viewModel.correctCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("問正解")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // 詳細
            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.answeredCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("解答数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    let accuracy = viewModel.answeredCount > 0
                        ? Int(Double(viewModel.correctCount) / Double(viewModel.answeredCount) * 100)
                        : 0
                    Text("\(accuracy)%")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("正答率")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // ボタン
            VStack(spacing: 12) {
                Button {
                    viewModel.start()
                } label: {
                    Text("もう一度挑戦")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    dismiss()
                } label: {
                    Text("ホームに戻る")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // 結果画面表示時に記録を保存
            viewModel.saveRecord(modelContext: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        TimeAttackView()
    }
    .environment(StoreManager.shared)
    .modelContainer(.preview)
}
