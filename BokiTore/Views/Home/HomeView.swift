import SwiftUI
import SwiftData

/// ホーム画面 — メインメニュー
struct HomeView: View {
    @Query private var allProgress: [UserProgress]

    /// 全体の正答率を計算
    private var overallAccuracy: Int {
        guard !allProgress.isEmpty else { return 0 }
        let correct = allProgress.filter { $0.isCorrect }.count
        return Int(Double(correct) / Double(allProgress.count) * 100)
    }

    /// 総問題数（QuestionLoaderから取得）
    private var totalQuestionCount: Int {
        QuestionLoader.shared.allQuestions.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // アプリタイトル
                Text("簿記トレ")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // メインボタン: 仕訳問題
                NavigationLink {
                    CategoryView()
                } label: {
                    HomeMenuCard(
                        icon: "pencil.and.list.clipboard",
                        title: "仕訳問題",
                        subtitle: "\(totalQuestionCount)問",
                        color: .appPrimary
                    )
                }

                // 学習統計ボタン
                NavigationLink {
                    StatsView()
                } label: {
                    HomeMenuCard(
                        icon: "chart.bar.fill",
                        title: "学習統計",
                        subtitle: "正答率 \(overallAccuracy)%",
                        color: .appSecondary
                    )
                }

                Spacer()

                // バナー広告の配置場所（Phase 5で実装）
                AdBannerPlaceholder()
            }
            .padding()
        }
    }
}

/// ホーム画面のメニューカード
struct HomeMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProgress.self, StudyStreak.self], inMemory: true)
}
