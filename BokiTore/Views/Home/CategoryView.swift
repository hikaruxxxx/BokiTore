import SwiftUI

/// カテゴリ選択画面 — 出題するカテゴリを選ぶ
struct CategoryView: View {
    /// 選択中の難易度フィルター（0 = 全て）
    @State private var selectedDifficulty = 0

    /// 難易度フィルターを適用した問題を返す
    private func filteredQuestions(_ questions: [Question]) -> [Question] {
        if selectedDifficulty == 0 { return questions }
        return questions.filter { $0.difficulty == selectedDifficulty }
    }

    var body: some View {
        List {
            // 難易度フィルター
            Section {
                Picker("難易度", selection: $selectedDifficulty) {
                    Text("すべて").tag(0)
                    Text("基本").tag(1)
                    Text("標準").tag(2)
                    Text("応用").tag(3)
                }
                .pickerStyle(.segmented)
            }

            // ランダム10問
            let randomPool = filteredQuestions(QuestionLoader.shared.allQuestions)
            NavigationLink {
                QuizView(questions: Array(randomPool.prefix(10)))
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                        .foregroundStyle(Color.appPrimary)
                    Text("ランダム10問")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(min(10, randomPool.count))問")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(randomPool.isEmpty)

            // 全問チャレンジ
            NavigationLink {
                QuizView(questions: filteredQuestions(QuestionLoader.shared.allQuestions))
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("全問チャレンジ")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(filteredQuestions(QuestionLoader.shared.allQuestions).count)問")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(filteredQuestions(QuestionLoader.shared.allQuestions).isEmpty)

            // サブカテゴリ別
            Section("カテゴリ別") {
                ForEach(JournalEntrySubcategory.allCases) { subcategory in
                    let questions = filteredQuestions(
                        QuestionLoader.shared.questions(forSubcategory: subcategory.rawValue)
                    )
                    NavigationLink {
                        QuizView(questions: questions)
                    } label: {
                        HStack {
                            Text(subcategory.displayName)
                            Spacer()
                            Text("\(questions.count)問")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(questions.isEmpty)
                }
            }
        }
        .navigationTitle("カテゴリ")
        .safeAreaInset(edge: .bottom) {
            if !StoreManager.shared.isPremium {
                AdBannerPlaceholder()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView()
    }
}
