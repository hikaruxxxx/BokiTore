import SwiftUI

/// カテゴリ別スコア棒グラフ — 診断結果のカテゴリ別表示
struct DiagnosisCategoryChart: View {
    let scores: [CategoryScore]

    /// スコアの最大値（バーの基準）
    private let maxScore: Int = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(scores.sorted(by: { $0.score < $1.score }), id: \.category) { score in
                HStack(spacing: 8) {
                    // カテゴリ名
                    Text(score.category)
                        .font(.caption)
                        .frame(width: 80, alignment: .trailing)
                        .lineLimit(1)

                    // スコアバー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景バー
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)

                            // スコアバー
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: score.score))
                                .frame(
                                    width: geometry.size.width * CGFloat(score.score) / CGFloat(maxScore),
                                    height: 16
                                )
                        }
                    }
                    .frame(height: 16)

                    // パーセント表示
                    Text("\(score.score)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(barColor(for: score.score))
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    /// スコアに応じたバーの色
    private func barColor(for score: Int) -> Color {
        if score >= 80 { return Color.appSecondary }
        if score >= 60 { return .orange }
        return Color.appError
    }
}

#Preview {
    DiagnosisCategoryChart(scores: [
        CategoryScore(category: "現金取引", score: 90, totalQuestions: 3, correctCount: 3),
        CategoryScore(category: "手形取引", score: 40, totalQuestions: 3, correctCount: 1),
        CategoryScore(category: "売買取引", score: 67, totalQuestions: 3, correctCount: 2),
        CategoryScore(category: "決算整理", score: 33, totalQuestions: 3, correctCount: 1),
        CategoryScore(category: "固定資産", score: 100, totalQuestions: 3, correctCount: 3)
    ])
    .padding()
}
