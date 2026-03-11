import SwiftUI
import SwiftData

/// 学習ロードマップ画面 — 診断結果に基づく弱点克服プラン
struct RoadmapView: View {
    @Query(filter: #Predicate<StudyRoadmap> { $0.isActive }) private var activeRoadmaps: [StudyRoadmap]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 初期スコア（診断結果画面から渡される場合）
    var initialScores: [CategoryScore]?

    /// アクティブなロードマップ
    private var roadmap: StudyRoadmap? {
        activeRoadmaps.first
    }

    /// ロードマップのステップ一覧
    private var steps: [RoadmapStep] {
        roadmap?.getSteps() ?? []
    }

    var body: some View {
        Group {
            if let roadmap {
                // ロードマップ表示
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 全体進捗
                        overallProgressSection(roadmap: roadmap)

                        // ステップ一覧
                        if !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("学習ステップ")
                                    .font(.headline)
                                    .padding(.bottom, 12)

                                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                    NavigationLink {
                                        QuizView(
                                            questions: QuestionLoader.shared.questions(for: step.category)
                                        )
                                    } label: {
                                        RoadmapStepRow(
                                            step: step,
                                            isLast: index == steps.count - 1
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        }
                    }
                    .padding()
                }
            } else {
                // ロードマップがない場合
                ContentUnavailableView(
                    "ロードマップがありません",
                    systemImage: "map",
                    description: Text("実力診断を受けてロードマップを作成しましょう")
                )
            }
        }
        .navigationTitle("学習ロードマップ")
        .onAppear {
            // 初期スコアがある場合はロードマップを生成
            if let scores = initialScores, roadmap == nil {
                generateRoadmap(from: scores)
            }
        }
    }

    /// 全体進捗セクション
    @ViewBuilder
    private func overallProgressSection(roadmap: StudyRoadmap) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("全体進捗")
                    .font(.headline)
                Spacer()
                Text("\(Int(roadmap.completionRate * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
            }

            ProgressView(value: roadmap.completionRate)
                .tint(.appPrimary)

            // 完了/未完了ステップ数
            let completed = steps.filter { $0.isCompleted }.count
            Text("\(completed)/\(steps.count)カテゴリ完了")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    /// 診断結果からロードマップを自動生成
    private func generateRoadmap(from scores: [CategoryScore]) {
        // 既存のアクティブなロードマップを無効化
        for existing in activeRoadmaps {
            existing.isActive = false
        }

        // スコアが低い順にステップを生成
        let sortedScores = scores.sorted { $0.score < $1.score }
        let roadmapSteps = sortedScores.enumerated().map { (index, score) in
            RoadmapStep(
                order: index,
                category: score.category,
                priority: score.score < 50 ? "high" : score.score < 70 ? "medium" : "low",
                targetScore: 80,
                currentScore: score.score,
                isCompleted: score.score >= 80
            )
        }

        let newRoadmap = StudyRoadmap(
            basedOnDiagnosisAt: .now,
            isActive: true
        )
        newRoadmap.setSteps(roadmapSteps)

        // 初期達成率を計算
        let completedCount = roadmapSteps.filter { $0.isCompleted }.count
        newRoadmap.completionRate = roadmapSteps.isEmpty ? 0 : Double(completedCount) / Double(roadmapSteps.count)

        modelContext.insert(newRoadmap)
    }
}

#Preview("ロードマップあり") {
    NavigationStack {
        RoadmapView()
    }
    .modelContainer(.preview)
}

#Preview("初期スコアから生成") {
    NavigationStack {
        RoadmapView(initialScores: [
            CategoryScore(category: "現金取引", score: 90, totalQuestions: 3, correctCount: 3),
            CategoryScore(category: "手形取引", score: 33, totalQuestions: 3, correctCount: 1),
            CategoryScore(category: "決算整理", score: 50, totalQuestions: 3, correctCount: 2)
        ])
    }
    .modelContainer(.preview)
}
