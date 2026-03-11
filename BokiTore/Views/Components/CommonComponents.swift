import SwiftUI

// MARK: - 共通UIコンポーネント

/// プライマリアクションボタン
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// セカンダリアクションボタン
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "次の問題 →") {}
        SecondaryButton(title: "ホームに戻る") {}
    }
    .padding()
}
