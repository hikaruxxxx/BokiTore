import SwiftUI

/// 難易度バッジ
struct DifficultyBadge: View {
    let level: Int

    /// 難易度に応じたラベルと色
    private var config: (text: String, color: Color) {
        switch level {
        case 1: return ("基本", .appSecondary)
        case 2: return ("標準", .orange)
        case 3: return ("応用", .appError)
        default: return ("--", .gray)
        }
    }

    var body: some View {
        Text(config.text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(config.color.opacity(0.15))
            .foregroundStyle(config.color)
            .clipShape(Capsule())
    }
}

/// 選択肢ボタン
struct ChoiceButton: View {
    let choice: Choice
    let isSelected: Bool
    let isCorrect: Bool?   // nil = まだ解答していない
    let isDisabled: Bool
    let action: () -> Void

    /// ボタンの背景色を決定
    private var backgroundColor: Color {
        guard let isCorrect else {
            return isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground)
        }
        if isCorrect && isSelected {
            return Color.appSecondary.opacity(0.15)
        } else if !isCorrect && isSelected {
            return Color.appError.opacity(0.15)
        } else if isCorrect {
            // 正解の選択肢は常に緑（未選択でも）
            return Color.appSecondary.opacity(0.08)
        }
        return Color(.systemBackground)
    }

    /// ボタンの枠線色
    private var borderColor: Color {
        guard let isCorrect else {
            return isSelected ? .appPrimary : Color(.separator)
        }
        if isCorrect {
            return .appSecondary
        } else if isSelected {
            return .appError
        }
        return Color(.separator)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(choice.id.uppercased()).")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading) {
                        Text("(借) \(choice.debit)")
                        Text("(貸) \(choice.credit)")
                    }
                    .font(.body)
                    Spacer()

                    // 解答後のアイコン表示（アニメーション付き）
                    if let isCorrect {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appSecondary)
                                .transition(.scale.combined(with: .opacity))
                        } else if isSelected {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.appError)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.3), value: isCorrect)
        }
        .disabled(isDisabled)
        .foregroundStyle(.primary)
    }
}

#Preview("難易度バッジ") {
    HStack {
        DifficultyBadge(level: 1)
        DifficultyBadge(level: 2)
        DifficultyBadge(level: 3)
    }
}
