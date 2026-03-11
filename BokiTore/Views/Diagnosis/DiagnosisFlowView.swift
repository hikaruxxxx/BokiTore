import SwiftUI

/// 実力診断フロー — 全カテゴリからサンプリング→クイズ→診断結果
struct DiagnosisFlowView: View {
    /// 診断用の問題（全カテゴリから均等サンプリング）
    @State private var diagnosisQuestions: [Question] = []

    var body: some View {
        Group {
            if diagnosisQuestions.isEmpty {
                // 問題生成中（通常は一瞬で完了）
                ProgressView("診断問題を準備中...")
                    .onAppear {
                        diagnosisQuestions = Self.sampleDiagnosisQuestions()
                    }
            } else {
                // 診断モードでクイズを開始
                QuizView(questions: diagnosisQuestions, isDiagnosisMode: true)
            }
        }
        .navigationTitle("実力診断")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 全セクション・全カテゴリから均等にサンプリングして診断用問題を生成
    /// セクション別 + サブカテゴリ別から各2〜3問ずつ抽出（合計20〜30問程度）
    static func sampleDiagnosisQuestions() -> [Question] {
        let allQuestions = QuestionLoader.shared.allQuestions
        var sampled: [Question] = []

        // セクション別にサンプリング（全フォーマット横断）
        let sections = Array(Set(allQuestions.compactMap { $0.examSection })).sorted()
        for section in sections {
            let sectionQuestions = allQuestions.filter { $0.examSection == section }
            // 各セクション内のサブカテゴリから均等に抽出
            let subcategories = Array(Set(sectionQuestions.map { $0.subcategory })).sorted()
            for subcategory in subcategories {
                let subQuestions = sectionQuestions.filter { $0.subcategory == subcategory }
                let count = min(2, subQuestions.count)
                sampled.append(contentsOf: subQuestions.shuffled().prefix(count))
            }
        }

        // セクション未設定の問題（既存multipleChoice等）もカテゴリ別で補完
        let noSectionQuestions = allQuestions.filter { $0.examSection == nil }
        if !noSectionQuestions.isEmpty {
            let categories = Array(Set(noSectionQuestions.map { $0.category })).sorted()
            for category in categories {
                let catQuestions = noSectionQuestions.filter { $0.category == category }
                let count = min(3, catQuestions.count)
                sampled.append(contentsOf: catQuestions.shuffled().prefix(count))
            }
        }

        // 最大30問に制限してシャッフル
        return Array(sampled.shuffled().prefix(30))
    }
}

#Preview {
    NavigationStack {
        DiagnosisFlowView()
    }
    .environment(StoreManager.shared)
    .modelContainer(.preview)
}
