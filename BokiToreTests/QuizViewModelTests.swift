import XCTest
import SwiftData
@testable import BokiTore

/// QuizViewModelのテスト
final class QuizViewModelTests: XCTestCase {

    /// テスト用の問題データを生成
    private func makeSampleQuestions() -> [Question] {
        [
            Question(
                id: "test001",
                category: "journalEntry",
                subcategory: "sales",
                difficulty: 1,
                questionType: "multipleChoice",
                questionText: "テスト問題1",
                choices: [
                    Choice(id: "a", debit: "売掛金 100", credit: "売上 100"),
                    Choice(id: "b", debit: "売上 100", credit: "売掛金 100"),
                    Choice(id: "c", debit: "買掛金 100", credit: "売上 100"),
                    Choice(id: "d", debit: "売掛金 100", credit: "仕入 100")
                ],
                correctAnswer: "a",
                explanation: "テスト解説1",
                tags: ["テスト"]
            ),
            Question(
                id: "test002",
                category: "journalEntry",
                subcategory: "purchase",
                difficulty: 1,
                questionType: "multipleChoice",
                questionText: "テスト問題2",
                choices: [
                    Choice(id: "a", debit: "仕入 200", credit: "買掛金 200"),
                    Choice(id: "b", debit: "買掛金 200", credit: "仕入 200"),
                    Choice(id: "c", debit: "仕入 200", credit: "売掛金 200"),
                    Choice(id: "d", debit: "売掛金 200", credit: "買掛金 200")
                ],
                correctAnswer: "a",
                explanation: "テスト解説2",
                tags: ["テスト"]
            )
        ]
    }

    /// 初期状態のテスト
    func testInitialState() {
        let vm = QuizViewModel(questions: makeSampleQuestions())
        XCTAssertNotNil(vm.currentQuestion, "最初の問題が表示されること")
        XCTAssertEqual(vm.totalCount, 2, "問題数が正しいこと")
        XCTAssertNil(vm.selectedAnswer, "初期状態で選択肢が未選択であること")
        XCTAssertFalse(vm.showResult, "初期状態で結果が非表示であること")
        XCTAssertFalse(vm.isCompleted, "初期状態で未完了であること")
    }

    /// 解答選択のテスト
    func testSelectAnswer() {
        let vm = QuizViewModel(questions: makeSampleQuestions())
        let correctAnswer = vm.currentQuestion!.correctAnswer
        vm.selectAnswer(correctAnswer)

        XCTAssertEqual(vm.selectedAnswer, correctAnswer, "選択した解答が設定されること")
        XCTAssertTrue(vm.showResult, "解答後に結果が表示されること")
        XCTAssertTrue(vm.isCurrentAnswerCorrect, "正解を選択した場合にtrueであること")
    }

    /// 不正解のテスト
    func testIncorrectAnswer() {
        let vm = QuizViewModel(questions: makeSampleQuestions())
        vm.selectAnswer("b") // 不正解を選択

        XCTAssertFalse(vm.isCurrentAnswerCorrect, "不正解の場合にfalseであること")
    }

    /// 進捗率のテスト
    func testProgress() {
        let vm = QuizViewModel(questions: makeSampleQuestions())
        XCTAssertEqual(vm.progress, 0.0, accuracy: 0.01, "初期進捗が0であること")
    }
}
