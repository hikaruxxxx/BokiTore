import SwiftUI
import SwiftData

/// ブックマーク一覧画面 — 保存した問題の表示と復習
struct BookmarkListView: View {
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Environment(\.modelContext) private var modelContext

    /// ブックマーク済みの問題データ
    private var bookmarkedQuestions: [Question] {
        let ids = bookmarks.map { $0.questionId }
        return QuestionLoader.shared.questions(byIds: ids)
    }

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                // 空状態
                ContentUnavailableView(
                    "ブックマークがありません",
                    systemImage: "bookmark",
                    description: Text("クイズの解答後にブックマークボタンで保存できます")
                )
            } else {
                List {
                    // 復習ボタン
                    if !bookmarkedQuestions.isEmpty {
                        Section {
                            NavigationLink {
                                QuizView(questions: bookmarkedQuestions)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundStyle(Color.appPrimary)
                                    Text("\(bookmarkedQuestions.count)問を復習する")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }

                    // ブックマークリスト
                    Section("保存した問題") {
                        ForEach(bookmarks) { bookmark in
                            BookmarkRow(bookmark: bookmark)
                        }
                        .onDelete { indexSet in
                            deleteBookmarks(at: indexSet)
                        }
                    }
                }
            }
        }
        .navigationTitle("ブックマーク")
    }

    /// ブックマークを削除
    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(bookmarks[index])
        }
    }
}

/// ブックマーク行の表示
struct BookmarkRow: View {
    let bookmark: Bookmark

    /// 問題データを取得
    private var question: Question? {
        QuestionLoader.shared.questions(byIds: [bookmark.questionId]).first
    }

    var body: some View {
        HStack {
            // 正解/不正解アイコン
            Image(systemName: bookmark.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(bookmark.wasCorrect ? Color.appSecondary : Color.appError)

            VStack(alignment: .leading, spacing: 4) {
                // 問題テキスト
                Text(question?.questionText ?? bookmark.questionId)
                    .font(.subheadline)
                    .lineLimit(2)

                // カテゴリ
                Text(bookmark.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkListView()
    }
    .modelContainer(.preview)
}
