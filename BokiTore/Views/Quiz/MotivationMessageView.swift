import SwiftUI

/// 解答後の励ましメッセージ — フェードイン+スライドアップで表示
struct MotivationMessageView: View {
    let isCorrect: Bool
    let comboCount: Int

    /// アニメーション用: 不透明度
    @State private var opacity: Double = 0
    /// アニメーション用: 垂直オフセット
    @State private var offset: CGFloat = 20

    /// 表示するメッセージを決定
    private var message: String {
        if comboCount >= 3 {
            return "🔥 \(comboCount)連続正解！"
        }
        if isCorrect {
            return Constants.Gamification.correctMessages.randomElement() ?? "正解！"
        }
        return Constants.Gamification.incorrectMessages.randomElement() ?? "次こそ！"
    }

    /// メッセージの色
    private var messageColor: Color {
        if comboCount >= 3 { return .orange }
        return isCorrect ? Color.appSecondary : Color.appError
    }

    var body: some View {
        Text(message)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(messageColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(messageColor.opacity(0.12))
            .clipShape(Capsule())
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                // フェードイン + スライドアップ
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    opacity = 1
                    offset = 0
                }
                // 1.5秒後にフェードアウト
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                }
            }
            .frame(maxWidth: .infinity)
    }
}

#Preview("正解メッセージ") {
    VStack(spacing: 20) {
        MotivationMessageView(isCorrect: true, comboCount: 0)
        MotivationMessageView(isCorrect: false, comboCount: 0)
        MotivationMessageView(isCorrect: true, comboCount: 5)
    }
    .padding()
}
