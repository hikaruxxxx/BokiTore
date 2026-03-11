import SwiftUI
import SwiftData

/// ストリークマイルストーンセクション（StatsViewに配置）
/// 7/30/100/365日のバッジをスクロール表示
struct StreakMilestoneSection: View {
    /// 現在の連続学習日数
    let consecutiveDays: Int
    /// 達成済みマイルストーン
    @Query(sort: \StreakMilestone.days) private var achieved: [StreakMilestone]

    /// 達成済みの日数セット（高速検索用）
    private var achievedDaysSet: Set<Int> {
        Set(achieved.map { $0.days })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ストリークマイルストーン")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Constants.Gamification.streakMilestones, id: \.days) { milestone in
                        let isAchieved = achievedDaysSet.contains(milestone.days)
                        let progress = min(Double(consecutiveDays) / Double(milestone.days), 1.0)
                        MilestoneBadge(
                            days: milestone.days,
                            rank: milestone.rank,
                            icon: milestone.icon,
                            isAchieved: isAchieved,
                            progress: progress
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 個別のマイルストーンバッジ
struct MilestoneBadge: View {
    let days: Int
    let rank: String
    let icon: String
    let isAchieved: Bool
    let progress: Double

    /// ランクに応じた色
    private var rankColor: Color {
        switch rank {
        case "Bronze": return .brown
        case "Silver": return .gray
        case "Gold": return .orange
        case "Master": return .purple
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // プログレスリング + アイコン
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 3)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: isAchieved ? 1.0 : progress)
                    .stroke(
                        rankColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isAchieved ? rankColor : Color(.systemFill))

                // 達成チェックマーク
                if isAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                        .background(Circle().fill(.white).frame(width: 14, height: 14))
                        .offset(x: 20, y: -20)
                }
            }

            // ランク名
            Text(rank)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(isAchieved ? rankColor : .secondary)

            // 日数 or 「達成!」
            if isAchieved {
                Text("達成!")
                    .font(.caption2)
                    .foregroundStyle(Color.appSecondary)
            } else {
                Text("あと\(days)日")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72)
    }
}

#Preview {
    List {
        Section {
            StreakMilestoneSection(consecutiveDays: 12)
        }
    }
    .modelContainer(.preview)
}
