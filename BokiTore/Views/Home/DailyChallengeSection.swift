import SwiftUI

/// ホーム画面のデイリーチャレンジセクション
struct DailyChallengeSection: View {
    let missions: [DailyMission]

    /// 全ミッション達成済みか
    private var allCompleted: Bool {
        missions.allSatisfy { $0.isCompleted }
    }

    /// お祝い演出表示（1日1回のみ自動表示）
    @State private var showCelebration = false
    @AppStorage("lastDailyCelebrationDate") private var lastCelebrationDate = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.orange)
                Text("今日のチャレンジ")
                    .font(.headline)
                Spacer()
                if allCompleted {
                    // お祝いボタン（タップで紙吹雪表示）
                    Button {
                        showCelebration = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "party.popper.fill")
                                .foregroundStyle(.orange)
                            Text("コンプリート!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.appSecondary)
                        }
                    }
                } else {
                    Text("\(missions.filter { $0.isCompleted }.count)/\(missions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // ミッション一覧
            ForEach(missions, id: \.orderIndex) { mission in
                DailyMissionRow(mission: mission)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .overlay {
            if showCelebration {
                CelebrationOverlay(
                    isShowing: $showCelebration,
                    title: "コンプリート!",
                    subtitle: "今日のチャレンジ達成 🎉"
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: allCompleted) { _, newValue in
            // 全達成時に1日1回のみ自動でお祝い表示
            if newValue {
                let today = formatToday()
                if lastCelebrationDate != today {
                    lastCelebrationDate = today
                    showCelebration = true
                }
            }
        }
    }

    /// 今日の日付を文字列に変換（キャッシュ済みFormatter使用）
    private func formatToday() -> String {
        DateFormatter.isoDate.string(from: .now)
    }
}

/// デイリーミッションの1行
struct DailyMissionRow: View {
    let mission: DailyMission

    /// 進捗率（0.0〜1.0）
    private var progress: Double {
        guard mission.targetValue > 0 else { return 0 }
        return min(Double(mission.currentValue) / Double(mission.targetValue), 1.0)
    }

    var body: some View {
        HStack(spacing: 10) {
            // チェックマーク or 進捗
            if mission.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appSecondary)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 20, height: 20)
            }

            // ミッション説明
            Text(mission.descriptionText)
                .font(.subheadline)
                .strikethrough(mission.isCompleted)
                .foregroundStyle(mission.isCompleted ? .secondary : .primary)

            Spacer()

            // 進捗テキスト
            Text("\(mission.currentValue)/\(mission.targetValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack {
        DailyChallengeSection(missions: [])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
