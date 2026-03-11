import SwiftUI

/// 週間アクティビティ表示（棒グラフ風）
struct WeeklyActivityView: View {
    let streaks: [StudyStreak]

    /// 直近7日間のデータ
    private var weekData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return (date: today, count: 0)
            }
            let count = streaks
                .first { calendar.startOfDay(for: $0.date) == date }?
                .questionsAnswered ?? 0
            return (date: date, count: count)
        }
    }

    /// 最大解答数（グラフのスケール用）
    private var maxCount: Int {
        max(weekData.map { $0.count }.max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(weekData, id: \.date) { data in
                VStack(spacing: 4) {
                    // 解答数ラベル
                    if data.count > 0 {
                        Text("\(data.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // バー
                    RoundedRectangle(cornerRadius: 4)
                        .fill(data.count > 0 ? Color.appPrimary : Color(.systemFill))
                        .frame(height: max(CGFloat(data.count) / CGFloat(maxCount) * 60, 4))

                    // 曜日ラベル
                    Text(data.date.shortWeekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

/// 円形プログレスビュー（苦手問題の正答率表示用）
struct CircularProgressView: View {
    let progress: Double

    /// 正答率に応じた色
    private var color: Color {
        if progress >= 0.8 { return .appSecondary }
        if progress >= 0.5 { return .orange }
        return .appError
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

/// 統計行（アイコン付き）
struct StatRow: View {
    let label: String
    let value: String
    var icon: String = ""
    var color: Color = .appPrimary

    var body: some View {
        HStack {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
            }
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

/// カテゴリ別正答率行（プログレスバー付き）
struct CategoryAccuracyRow: View {
    let name: String
    let accuracy: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(accuracy)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(accuracyColor)
            }
            ProgressView(value: Double(accuracy), total: 100)
                .tint(accuracyColor)
        }
    }

    /// 正答率に応じた色
    private var accuracyColor: Color {
        if accuracy >= 80 { return .appSecondary }
        if accuracy >= 60 { return .orange }
        return .appError
    }
}
