import SwiftUI

/// 試験セクション選択画面 — 第1問/第2問/全問から選ぶ
/// 簿記3級本試験のセクション構成に対応したナビゲーション
struct ExamSectionView: View {
    /// プレミアム判定用（Environment経由で注入）
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        List {
            // ランダム10問（全フォーマット横断）
            let allQuestions = QuestionLoader.shared.allQuestions
            NavigationLink {
                QuizView(questions: Array(allQuestions.shuffled().prefix(10)))
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 28)
                    VStack(alignment: .leading) {
                        Text("ランダム10問")
                            .fontWeight(.semibold)
                        Text("全セクションから出題")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(min(10, allQuestions.count))問")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(allQuestions.isEmpty)

            // 全問チャレンジ
            NavigationLink {
                QuizView(questions: allQuestions)
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 28)
                    VStack(alignment: .leading) {
                        Text("全問チャレンジ")
                            .fontWeight(.semibold)
                        Text("すべてのセクション")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(allQuestions.count)問")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(allQuestions.isEmpty)

            // セクション別
            Section("試験セクション別") {
                ForEach(ExamSection.allCases) { section in
                    let questions = QuestionLoader.shared.questions(forExamSection: section.rawValue)

                    if section == .dai1 {
                        // 第1問はカテゴリ別に分けて表示（CategoryView経由）
                        NavigationLink {
                            CategoryView(examSection: section.rawValue)
                        } label: {
                            ExamSectionRow(section: section, count: questions.count)
                        }
                        .disabled(questions.isEmpty)
                    } else {
                        // 第2問は直接クイズ開始
                        NavigationLink {
                            QuizView(questions: questions.shuffled())
                        } label: {
                            ExamSectionRow(section: section, count: questions.count)
                        }
                        .disabled(questions.isEmpty)
                    }
                }
            }
        }
        .navigationTitle("問題を解く")
        .safeAreaInset(edge: .bottom) {
            if !storeManager.isPremium {
                AdBannerPlaceholder()
            }
        }
    }
}

/// セクション行の表示
private struct ExamSectionRow: View {
    let section: ExamSection
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: section.iconName)
                .foregroundStyle(section.color)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(section.displayName)
                    .fontWeight(.semibold)
                Text(section.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(count)問")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ExamSectionView()
    }
    .environment(StoreManager.shared)
}
