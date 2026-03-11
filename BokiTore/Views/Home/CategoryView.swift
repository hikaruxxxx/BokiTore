import SwiftUI
import SwiftData

/// カテゴリ選択画面 — 出題するカテゴリを選ぶ
/// examSection指定時はそのセクションの問題のみ表示
struct CategoryView: View {
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager
    @Query private var allProgress: [UserProgress]
    /// 選択中の難易度フィルター（0 = 全て）
    @State private var selectedDifficulty = 0
    /// 絞り込む試験セクション（nilなら全問）
    let examSection: String?

    init(examSection: String? = nil) {
        self.examSection = examSection
    }

    /// ベースとなる問題プール（examSection指定時はセクション絞り込み）
    private var baseQuestions: [Question] {
        if let examSection {
            return QuestionLoader.shared.questions(forExamSection: examSection)
        }
        return QuestionLoader.shared.allQuestions
    }

    /// 難易度フィルターを適用した問題を返す
    private func filteredQuestions(_ questions: [Question]) -> [Question] {
        if selectedDifficulty == 0 { return questions }
        return questions.filter { $0.difficulty == selectedDifficulty }
    }

    /// ベース問題のサブカテゴリ一覧
    private var subcategories: [String] {
        Array(Set(baseQuestions.map { $0.subcategory })).sorted()
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
            let randomPool = filteredQuestions(baseQuestions)
            NavigationLink {
                QuizView(questions: Array(randomPool.shuffled().prefix(10)))
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
                QuizView(questions: filteredQuestions(baseQuestions))
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("全問チャレンジ")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(filteredQuestions(baseQuestions).count)問")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(filteredQuestions(baseQuestions).isEmpty)

            // サブカテゴリ別
            Section("カテゴリ別") {
                ForEach(subcategories, id: \.self) { subcategory in
                    let questions = filteredQuestions(
                        baseQuestions.filter { $0.subcategory == subcategory }
                    )
                    let masteryLevel = calculateMasteryLevel(
                        progress: allProgress,
                        subcategory: subcategory
                    )
                    NavigationLink {
                        QuizView(questions: questions)
                    } label: {
                        HStack {
                            MasteryBadgeInline(level: masteryLevel)
                            Text(subcategory)
                            Spacer()
                            Text("\(questions.count)問")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(questions.isEmpty)
                }
            }
        }
        .navigationTitle(examSection ?? "カテゴリ")
        .safeAreaInset(edge: .bottom) {
            if !storeManager.isPremium {
                AdBannerPlaceholder()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView()
    }
    .environment(StoreManager.shared)
    .modelContainer(.preview)
}
