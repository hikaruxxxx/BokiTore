import SwiftUI

/// コンボインジケーター — 3連続正解以上で🔥表示
struct ComboIndicatorView: View {
    let count: Int

    /// スプリングアニメーション用スケール
    @State private var scale: CGFloat = 0.5

    var body: some View {
        if count >= 3 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Text("\(count)連続正解！")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
            .scaleEffect(scale)
            .onAppear {
                // 登場アニメーション
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
            .onChange(of: count) {
                // カウント変化時にバウンスアニメーション
                scale = 0.8
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
        }
    }
}

#Preview("コンボインジケーター") {
    VStack(spacing: 20) {
        ComboIndicatorView(count: 2) // 非表示
        ComboIndicatorView(count: 3)
        ComboIndicatorView(count: 5)
        ComboIndicatorView(count: 10)
    }
    .padding()
}
