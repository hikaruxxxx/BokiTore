import Foundation

/// 正解判定を一箇所に集約するユーティリティ
/// フォーマットごとに異なる正解判定ロジックをここで管理する
enum AnswerChecker {

    /// 問題とユーザーの解答を照合して正解かどうかを返す
    /// - Parameters:
    ///   - question: 出題された問題
    ///   - answer: ユーザーの解答
    /// - Returns: 正解なら true
    static func check(question: Question, answer: UserAnswer) -> Bool {
        switch answer {
        case .multipleChoice(let choiceId):
            return checkMultipleChoice(question: question, choiceId: choiceId)

        case .journalEntry(let entries):
            return checkJournalEntry(question: question, entries: entries)

        case .tAccountFill(let answers):
            return checkTAccountFill(question: question, answers: answers)

        case .subledgerSelect(let selections):
            return checkSubledgerSelect(question: question, selections: selections)

        case .theoryFill(let answers):
            return checkTheoryFill(question: question, answers: answers)
        }
    }

    // MARK: - フォーマット別の判定ロジック

    /// 4択: 選択したIDが正解と一致するか
    private static func checkMultipleChoice(question: Question, choiceId: String) -> Bool {
        choiceId == question.correctAnswer
    }

    /// CBT仕訳入力: 仕訳行のセット一致（順序不問）
    private static func checkJournalEntry(question: Question, entries: [JournalLine]) -> Bool {
        guard case .journalEntry(let data) = question.questionData else { return false }

        // 空行を除外して比較
        let userKeys = Set(entries.filter { !$0.account.isEmpty && $0.amount > 0 }
            .map { $0.comparisonKey })
        let correctKeys = Set(data.correctEntries.map { $0.comparisonKey })

        return userKeys == correctKeys
    }

    /// T勘定空欄補充: 全空欄が正解と一致するか
    private static func checkTAccountFill(question: Question, answers: [String: String]) -> Bool {
        guard case .tAccountFill(let data) = question.questionData else { return false }

        return data.blanks.allSatisfy { blank in
            // 金額の場合はカンマ・空白を除去して比較
            if blank.answerType == "amount" {
                let userValue = answers[blank.id]?.replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces) ?? ""
                let correctValue = blank.correctAnswer.replacingOccurrences(of: ",", with: "")
                return userValue == correctValue
            }
            // 勘定科目・摘要はそのまま文字列比較
            return answers[blank.id] == blank.correctAnswer
        }
    }

    /// 補助簿選択: 全取引で選択した補助簿セットが正解と一致するか
    private static func checkSubledgerSelect(
        question: Question,
        selections: [String: Set<String>]
    ) -> Bool {
        guard case .subledgerSelect(let data) = question.questionData else { return false }

        return data.transactions.allSatisfy { transaction in
            let userSet = selections[transaction.id] ?? []
            let correctSet = Set(transaction.correctSubledgers)
            return userSet == correctSet
        }
    }

    /// 理論穴埋め: 全空欄で選択した語句が正解と一致するか
    private static func checkTheoryFill(question: Question, answers: [String: String]) -> Bool {
        guard case .theoryFill(let data) = question.questionData else { return false }

        return data.blanks.allSatisfy { blank in
            answers[blank.id] == blank.correctAnswer
        }
    }
}
