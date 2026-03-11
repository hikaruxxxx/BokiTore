import SwiftUI

/// ホーム画面上部の日次目標プログレスリング
struct StudyPlanProgressView: View {
    /// 今日の解答数
    let todayAnswered: Int
    /// 日次目標
    let dailyGoal: Int
    /// 試験日（設定されている場合）
    let examDate: Date?

    /// 達成率（0.0〜1.0）
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todayAnswered) / Double(dailyGoal), 1.0)
    }

    /// 試験までの残り日数
    private var daysUntilExam: Int? {
        guard let examDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: .now, to: examDate).day
        return days
    }

    /// プログレスに応じた色
    private var progressColor: Color {
        if progress >= 1.0 { return .appSecondary }
        if progress >= 0.5 { return .appPrimary }
        return .orange
    }

    var body: some View {
        HStack(spacing: 16) {
            // 円形プログレス
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 0) {
                    if progress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appSecondary)
                    } else {
                        Text("\(todayAnswered)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/\(dailyGoal)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 70, height: 70)

            // テキスト情報
            VStack(alignment: .leading, spacing: 4) {
                if progress >= 1.0 {
                    Text("今日の目標達成!")
                        .font(.headline)
                        .foregroundStyle(Color.appSecondary)
                } else {
                    Text("今日のノルマ")
                        .font(.headline)
                    Text("あと\(max(dailyGoal - todayAnswered, 0))問")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let days = daysUntilExam, days >= 0 {
                    Text("試験まであと\(days)日")
                        .font(.caption)
                        .foregroundStyle(Color.appPrimary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        StudyPlanProgressView(todayAnswered: 3, dailyGoal: 10, examDate: Date().daysFromNow(30))
        StudyPlanProgressView(todayAnswered: 10, dailyGoal: 10, examDate: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
