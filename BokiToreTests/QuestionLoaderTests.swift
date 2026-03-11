import XCTest
@testable import BokiTore

/// QuestionLoaderのテスト
final class QuestionLoaderTests: XCTestCase {

    /// JSONが正常に読み込めるかテスト
    func testLoadQuestions() {
        let loader = QuestionLoader.shared
        XCTAssertFalse(loader.allQuestions.isEmpty, "問題データが読み込まれていること")
    }

    /// カテゴリでフィルタリングできるかテスト
    func testFilterByCategory() {
        let loader = QuestionLoader.shared
        let journalEntries = loader.questions(for: "journalEntry")
        XCTAssertFalse(journalEntries.isEmpty, "仕訳問題が存在すること")

        // 全問が指定カテゴリであること
        for question in journalEntries {
            XCTAssertEqual(question.category, "journalEntry")
        }
    }

    /// 問題のデータ構造が正しいかテスト
    func testQuestionStructure() {
        let loader = QuestionLoader.shared
        guard let question = loader.allQuestions.first else {
            XCTFail("問題データが空です")
            return
        }

        // 必須フィールドが存在すること
        XCTAssertFalse(question.id.isEmpty, "IDが設定されていること")
        XCTAssertFalse(question.questionText.isEmpty, "問題文が設定されていること")
        XCTAssertFalse(question.choices.isEmpty, "選択肢が設定されていること")
        XCTAssertFalse(question.correctAnswer.isEmpty, "正解が設定されていること")
        XCTAssertFalse(question.explanation.isEmpty, "解説が設定されていること")

        // 選択肢が4つあること
        XCTAssertEqual(question.choices.count, 4, "選択肢は4つであること")

        // 正解の選択肢が存在すること
        let correctChoice = question.choices.first { $0.id == question.correctAnswer }
        XCTAssertNotNil(correctChoice, "正解の選択肢が存在すること")
    }

    /// ランダム取得が機能するかテスト
    func testRandomQuestions() {
        let loader = QuestionLoader.shared
        let random5 = loader.randomQuestions(count: 5)
        XCTAssertEqual(random5.count, min(5, loader.allQuestions.count), "指定数の問題が返ること")
    }
}
