import SwiftUI

/// 解説表示ビュー — 正解/不正解の結果と解説を表示
struct ExplanationView: View {
    let isCorrect: Bool
    let explanation: String
    let correctChoice: Choice?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 正解/不正解の表示
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(isCorrect ? Color.appSecondary : Color.appError)

                Text(isCorrect ? "正解！" : "不正解")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(isCorrect ? Color.appSecondary : Color.appError)
            }

            // 正しい仕訳の表示
            if let correctChoice {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正しい仕訳:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("(借) \(correctChoice.debit)")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("(貸) \(correctChoice.credit)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSecondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 解説テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text("解説")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(explanation)
                    .font(.callout)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ExplanationView(
        isCorrect: true,
        explanation: "掛けでの売上は、借方に売掛金（資産の増加）、貸方に売上（収益の発生）を記入します。",
        correctChoice: Choice(id: "a", debit: "売掛金 100,000", credit: "売上 100,000")
    )
    .padding()
}
