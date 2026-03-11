import SwiftUI
import SwiftData

/// ブックマークボタン — 解答後に問題をブックマーク追加/削除
struct BookmarkButton: View {
    let questionId: String
    let wasCorrect: Bool
    let category: String
    @Environment(\.modelContext) private var modelContext
    @State private var isBookmarked = false

    var body: some View {
        Button {
            toggleBookmark()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isBookmarked ? Color.appPrimary : .secondary)
                Text(isBookmarked ? "ブックマーク済み" : "ブックマークに追加")
                    .font(.subheadline)
                    .foregroundStyle(isBookmarked ? Color.appPrimary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isBookmarked
                    ? Color.appPrimary.opacity(0.1)
                    : Color(.secondarySystemBackground)
            )
            .clipShape(Capsule())
        }
        .onAppear {
            checkBookmarkStatus()
        }
    }

    /// ブックマーク状態をチェック
    private func checkBookmarkStatus() {
        do {
            let id = questionId
            let descriptor = FetchDescriptor<Bookmark>(
                predicate: #Predicate { $0.questionId == id }
            )
            let existing = try modelContext.fetch(descriptor)
            isBookmarked = !existing.isEmpty
        } catch {
            #if DEBUG
            print("ブックマーク状態チェックエラー: \(error)")
            #endif
        }
    }

    /// ブックマークをトグル（追加/削除）
    private func toggleBookmark() {
        do {
            let id = questionId
            let descriptor = FetchDescriptor<Bookmark>(
                predicate: #Predicate { $0.questionId == id }
            )
            let existing = try modelContext.fetch(descriptor)

            if let bookmark = existing.first {
                // 既存のブックマークを削除
                modelContext.delete(bookmark)
                isBookmarked = false
            } else {
                // 新しいブックマークを作成
                let bookmark = Bookmark(
                    questionId: questionId,
                    wasCorrect: wasCorrect,
                    category: category
                )
                modelContext.insert(bookmark)
                isBookmarked = true
            }
        } catch {
            #if DEBUG
            print("ブックマークトグルエラー: \(error)")
            #endif
        }
    }
}

#Preview {
    BookmarkButton(
        questionId: "test_001",
        wasCorrect: true,
        category: "仕訳"
    )
    .modelContainer(.preview)
}
