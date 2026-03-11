import SwiftUI
import SwiftData

/// 実力診断結果画面 — 総合スコア、カテゴリ別分析、弱点表示
struct DiagnosisResultView: View {
    let viewModel: QuizViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var categoryScores: [CategoryScore] = []
    @State private var weakCategories: [String] = []
    @State private var overallScore: Int = 0
    @State private var passRate: Double = 0.0
    @State private var hasSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 総合スコア
                VStack(spacing: 8) {
                    Text("総合スコア")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(overallScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)

                    Text("/ 100")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // 推定合格確率
                VStack(spacing: 4) {
                    Text("推定合格確率")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(passRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(passRate >= 0.7 ? Color.appSecondary : Color.appError)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // カテゴリ別スコア
                if !categoryScores.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("カテゴリ別スコア")
                            .font(.headline)
                        DiagnosisCategoryChart(scores: categoryScores)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)
                }

                // 弱点カテゴリ
                if !weakCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("重点強化カテゴリ")
                            .font(.headline)
                        ForEach(weakCategories, id: \.self) { category in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(category)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // ボタン群
                VStack(spacing: 12) {
                    // ロードマップ作成ボタン
                    if !categoryScores.isEmpty {
                        NavigationLink {
                            RoadmapView(initialScores: categoryScores)
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("学習ロードマップを作成")
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
                .padding(.bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !hasSaved {
                calculateAndSaveResult()
                hasSaved = true
            }
        }
    }

    /// スコアに応じた色
    private var scoreColor: Color {
        if overallScore >= 80 { return Color.appSecondary }
        if overallScore >= 60 { return .orange }
        return Color.appError
    }

    /// セッション結果からスコアを計算してSwiftDataに保存
    private func calculateAndSaveResult() {
        let session = viewModel.session

        // カテゴリ別集計
        var categoryData: [String: (correct: Int, total: Int)] = [:]
        for question in session.questions {
            let isCorrect = session.answers[question.id] ?? false
            let existing = categoryData[question.category] ?? (correct: 0, total: 0)
            categoryData[question.category] = (
                correct: existing.correct + (isCorrect ? 1 : 0),
                total: existing.total + 1
            )
        }

        // CategoryScore配列を生成
        let scores = categoryData.map { (category, data) in
            CategoryScore(
                category: category,
                score: data.total > 0 ? Int(Double(data.correct) / Double(data.total) * 100) : 0,
                totalQuestions: data.total,
                correctCount: data.correct
            )
        }
        categoryScores = scores

        // 総合スコア
        overallScore = Int(session.accuracy * 100)

        // 推定合格確率（簡易計算: スコアが70以上で高確率）
        passRate = min(1.0, max(0.0, (session.accuracy - 0.3) / 0.5))

        // 弱点カテゴリ（60%未満）
        weakCategories = scores.filter { $0.score < 60 }.map { $0.category }

        // DiagnosisResult を保存
        let result = DiagnosisResult(
            diagnosedAt: .now,
            overallScore: overallScore,
            estimatedPassRate: passRate,
            totalQuestions: session.questions.count,
            correctCount: session.correctCount,
            durationSec: Int(session.totalTimeSpent)
        )
        result.setCategoryScores(scores)
        result.setWeakCategories(weakCategories)
        modelContext.insert(result)
    }
}

#Preview {
    NavigationStack {
        DiagnosisResultView(
            viewModel: QuizViewModel(questions: QuestionLoader.shared.allQuestions)
        )
    }
    .modelContainer(.preview)
}
