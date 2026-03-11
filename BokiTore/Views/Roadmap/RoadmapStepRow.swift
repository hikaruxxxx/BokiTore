import SwiftUI

/// ロードマップの1ステップ行 — タイムライン風表示
struct RoadmapStepRow: View {
    let step: RoadmapStep
    let isLast: Bool

    /// ステップの状態に応じたインジケーター色
    private var indicatorColor: Color {
        if step.isCompleted { return Color.appSecondary }
        if step.currentScore > 0 { return Color.appPrimary }
        return Color(.systemGray4)
    }

    /// 優先度に応じたバッジ色
    private var priorityColor: Color {
        switch step.priority {
        case "high": return Color.appError
        case "medium": return .orange
        default: return Color.appSecondary
        }
    }

    /// 優先度の日本語表示
    private var priorityLabel: String {
        switch step.priority {
        case "high": return "高"
        case "medium": return "中"
        default: return "低"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左: タイムラインインジケーター
            VStack(spacing: 0) {
                // 丸インジケーター
                ZStack {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 28, height: 28)

                    if step.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(step.order + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

                // 接続線（最後のステップ以外）
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            // 中央: カテゴリ情報
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(step.category)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // 優先度バッジ
                    Text(priorityLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                }

                // スコア表示
                HStack(spacing: 4) {
                    Text("\(step.currentScore)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(step.isCompleted ? Color.appSecondary : .primary)
                    Text("→")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(step.targetScore)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 進捗バー
                ProgressView(value: Double(step.currentScore), total: Double(step.targetScore))
                    .tint(indicatorColor)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        RoadmapStepRow(
            step: RoadmapStep(order: 0, category: "手形取引", priority: "high", targetScore: 80, currentScore: 30, isCompleted: false),
            isLast: false
        )
        RoadmapStepRow(
            step: RoadmapStep(order: 1, category: "決算整理", priority: "medium", targetScore: 80, currentScore: 55, isCompleted: false),
            isLast: false
        )
        RoadmapStepRow(
            step: RoadmapStep(order: 2, category: "現金取引", priority: "low", targetScore: 80, currentScore: 80, isCompleted: true),
            isLast: true
        )
    }
    .padding()
}
