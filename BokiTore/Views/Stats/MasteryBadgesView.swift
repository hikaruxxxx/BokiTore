import SwiftUI

/// マスタリーランク
enum MasteryLevel: String, CaseIterable {
    case none = "未達成"
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case master = "Master"

    /// ランクに対応するアイコン
    var icon: String {
        switch self {
        case .none: return "shield"
        case .bronze: return "shield.fill"
        case .silver: return "shield.fill"
        case .gold: return "shield.fill"
        case .master: return "crown.fill"
        }
    }

    /// ランクに対応する色
    var color: Color {
        switch self {
        case .none: return .gray
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .master: return Color(red: 0.6, green: 0.2, blue: 0.8)
        }
    }
}

/// 解答履歴からマスタリーレベルを計算する
func calculateMasteryLevel(progress: [UserProgress], subcategory: String) -> MasteryLevel {
    let questions = QuestionLoader.shared.questions(forSubcategory: subcategory)
    let questionIds = Set(questions.map { $0.id })
    let categoryProgress = progress.filter { questionIds.contains($0.questionId) }

    guard !categoryProgress.isEmpty else { return .none }

    let count = categoryProgress.count
    let correct = categoryProgress.filter { $0.isCorrect }.count
    let accuracy = Double(correct) / Double(count)

    let thresholds = Constants.Gamification.masteryThresholds

    // 最も高いランクから順にチェック
    for i in stride(from: thresholds.count - 1, through: 0, by: -1) {
        let threshold = thresholds[i]
        if count >= threshold.minCount && accuracy >= threshold.minAccuracy {
            switch i {
            case 0: return .bronze
            case 1: return .silver
            case 2: return .gold
            case 3: return .master
            default: return .none
            }
        }
    }

    return .none
}

/// カテゴリ別マスタリーバッジのグリッド表示
struct MasteryBadgesView: View {
    let allProgress: [UserProgress]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(JournalEntrySubcategory.allCases) { subcategory in
                let level = calculateMasteryLevel(
                    progress: allProgress,
                    subcategory: subcategory.rawValue
                )
                MasteryBadgeCard(
                    name: subcategory.displayName,
                    level: level
                )
            }
        }
    }
}

/// マスタリーバッジカード（1カテゴリ分）
struct MasteryBadgeCard: View {
    let name: String
    let level: MasteryLevel

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(.title2)
                .foregroundStyle(level.color)

            Text(name)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(level.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(level == .none ? Color(.systemFill).opacity(0.5) : level.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// マスタリーバッジ（インライン表示用、CategoryViewのサブカテゴリ行で使う）
struct MasteryBadgeInline: View {
    let level: MasteryLevel

    var body: some View {
        if level != .none {
            Image(systemName: level.icon)
                .font(.caption)
                .foregroundStyle(level.color)
        }
    }
}

#Preview {
    MasteryBadgesView(allProgress: [])
        .padding()
}
