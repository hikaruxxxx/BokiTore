import Foundation

/// ユーザーの解答（フォーマット別に異なるデータ構造を持つ）
enum UserAnswer {
    /// 4択から1つ選択（従来の multipleChoice）
    case multipleChoice(choiceId: String)

    /// CBT仕訳入力（借方/貸方の仕訳行リスト）
    case journalEntry(entries: [JournalLine])

    /// T勘定空欄補充（空欄ID → 回答値）
    case tAccountFill(answers: [String: String])

    /// 補助簿選択（取引ID → 選択した補助簿セット）
    case subledgerSelect(selections: [String: Set<String>])

    /// 理論穴埋め（空欄ID → 選択した語句）
    case theoryFill(answers: [String: String])

    /// multipleChoice の選択IDを取得（ChoiceButton表示判定用）
    /// 他フォーマットでは nil を返す
    var multipleChoiceId: String? {
        if case .multipleChoice(let choiceId) = self {
            return choiceId
        }
        return nil
    }
}
