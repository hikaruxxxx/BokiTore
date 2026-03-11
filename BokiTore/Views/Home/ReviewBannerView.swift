import SwiftUI

/// ホーム画面の復習バナー（期限の復習問題がある場合に表示）
struct ReviewBannerView: View {
    /// 復習問題数
    let count: Int
    /// 復習対象の問題リスト
    let questions: [Question]

    var body: some View {
        NavigationLink {
            QuizView(questions: questions)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日の復習")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(count)問の復習問題があります")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ReviewBannerView(count: 5, questions: [])
        .padding()
}
