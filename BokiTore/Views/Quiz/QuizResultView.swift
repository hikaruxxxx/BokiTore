import SwiftUI
import SwiftData

/// 結果画面 — mikan式の演出付きクイズ結果表示
struct QuizResultView: View {
    let viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    /// レビュー判定用：累計正解数（正解のみフィルタ済み — 全件ロードを回避）
    @Query(filter: #Predicate<UserProgress> { $0.isCorrect }) private var correctProgress: [UserProgress]
    /// レビュー判定用：学習日数
    @Query private var streaks: [StudyStreak]
    /// クロスプロモーション用：学習計画
    @Query private var studyPlans: [StudyPlan]
    @State private var showCelebration = false

    /// 学習計画（ターゲティング用）
    private var studyPlan: StudyPlan? {
        studyPlans.first { $0.isOnboardingCompleted }
    }

    /// 正答率に応じたランク情報
    private var rankInfo: (title: String, subtitle: String) {
        let accuracy = viewModel.session.accuracy
        for rank in Constants.Gamification.resultRanks {
            if accuracy >= rank.minAccuracy {
                return (rank.title, rank.subtitle)
            }
        }
        return ("挑戦者", "復習して強くなろう！")
    }

    /// 正答率80%以上なら紙吹雪を表示
    private var shouldCelebrate: Bool {
        viewModel.session.accuracy >= 0.8
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ランクタイトル
                    VStack(spacing: 8) {
                        Text(rankInfo.title)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appPrimary)

                        Text(rankInfo.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // 結果カード（mikan式）
                    VStack(spacing: 16) {
                        // わかった数
                        VStack(spacing: 4) {
                            Text("わかった数")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.session.correctCount) / \(viewModel.totalCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.session.accuracy >= 0.8 ? Color.appSecondary : Color.appPrimary)
                        }

                        Divider()

                        // 解答時間 + 正答率
                        HStack(spacing: 0) {
                            // 解答時間
                            VStack(spacing: 4) {
                                Text("解答時間")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption)
                                    Text(viewModel.formattedTotalTime)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            Divider()
                                .frame(height: 30)

                            // 正答率
                            VStack(spacing: 4) {
                                Text("正答率")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(viewModel.session.accuracy * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        viewModel.session.accuracy >= 0.8 ? Color.appSecondary : Color.appError
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // ボタン群
                    VStack(spacing: 12) {
                        // 間違えた問題を復習（目立つ配置）
                        if !viewModel.incorrectQuestions.isEmpty {
                            NavigationLink {
                                QuizView(questions: viewModel.incorrectQuestions)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("\(viewModel.incorrectQuestions.count)問を復習")
                                }
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
                    .padding(.horizontal)

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
                        .padding(.horizontal)
                    }

                    // クロスプロモーションバナー（ターゲティング付き）
                    CrossPromoBannerView(
                        placement: "quiz_result",
                        userCerts: studyPlan?.getInterestedCerts() ?? [],
                        userPurpose: studyPlan?.studyPurpose ?? ""
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }

            // 紙吹雪（正答率80%以上で表示）
            if showCelebration {
                CelebrationOverlay(
                    isShowing: $showCelebration,
                    title: rankInfo.title,
                    subtitle: rankInfo.subtitle
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            if !storeManager.isPremium {
                AdBannerPlaceholder()
            }
        }
        .onAppear {
            // セッション完了フィードバック（触覚）
            FeedbackManager.sessionComplete()

            if shouldCelebrate {
                showCelebration = true
            }
            // Firebase Analyticsにセッション完了イベントを送信
            AnalyticsManager.logSessionCompleted(
                totalQuestions: viewModel.totalCount,
                correctCount: viewModel.session.correctCount,
                accuracy: viewModel.session.accuracy,
                sessionDurationSec: viewModel.session.totalTimeSpent
            )
            // レビュー依頼の判定（ポジティブな体験の直後に表示）
            let totalCorrect = correctProgress.count
            ReviewManager.requestReviewIfEligible(
                totalCorrect: totalCorrect,
                studyDays: streaks.count,
                sessionAccuracy: viewModel.session.accuracy
            )
        }
    }
}

#Preview {
    NavigationStack {
        QuizResultView(
            viewModel: QuizViewModel(questions: QuestionLoader.shared.allQuestions)
        )
    }
    .environment(StoreManager.shared)
    .modelContainer(.preview)
}
