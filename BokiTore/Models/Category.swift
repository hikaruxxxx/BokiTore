import SwiftUI

/// 問題カテゴリの定義
enum QuestionCategory: String, CaseIterable, Identifiable {
    case journalEntry = "journalEntry"
    case accountTitle = "accountTitle"
    case trialBalance = "trialBalance"
    case financialStatements = "financialStatements"
    case vocabulary = "vocabulary"

    var id: String { rawValue }

    /// カテゴリの日本語名
    var displayName: String {
        switch self {
        case .journalEntry: return "仕訳問題"
        case .accountTitle: return "勘定科目"
        case .trialBalance: return "試算表"
        case .financialStatements: return "財務諸表"
        case .vocabulary: return "簿記用語"
        }
    }

    /// カテゴリのアイコン
    var iconName: String {
        switch self {
        case .journalEntry: return "pencil.and.list.clipboard"
        case .accountTitle: return "list.bullet.rectangle"
        case .trialBalance: return "tablecells"
        case .financialStatements: return "doc.text"
        case .vocabulary: return "textbook.closed"
        }
    }
}

/// サブカテゴリの定義（仕訳問題用）
enum JournalEntrySubcategory: String, CaseIterable, Identifiable {
    case cashDeposit = "cashDeposit"
    case accountsReceivablePayable = "accountsReceivablePayable"
    case notes = "notes"
    case securities = "securities"
    case fixedAssets = "fixedAssets"
    case capital = "capital"
    case revenueExpense = "revenueExpense"
    case adjustingEntries = "adjustingEntries"
    case trialBalance = "trialBalance"
    case worksheet = "worksheet"

    var id: String { rawValue }

    /// サブカテゴリの日本語名
    var displayName: String {
        switch self {
        case .cashDeposit: return "現金・預金"
        case .accountsReceivablePayable: return "売掛金・買掛金"
        case .notes: return "手形"
        case .securities: return "有価証券"
        case .fixedAssets: return "固定資産"
        case .capital: return "資本金・引出金"
        case .revenueExpense: return "収益・費用"
        case .adjustingEntries: return "決算整理仕訳"
        case .trialBalance: return "試算表"
        case .worksheet: return "精算表"
        }
    }

    /// 予定問題数
    var questionCount: Int {
        switch self {
        case .cashDeposit: return 40
        case .accountsReceivablePayable: return 35
        case .notes: return 30
        case .securities: return 25
        case .fixedAssets: return 30
        case .capital: return 20
        case .revenueExpense: return 50
        case .adjustingEntries: return 45
        case .trialBalance: return 25
        case .worksheet: return 20
        }
    }
}

// MARK: - 試験セクション

/// 簿記3級本試験のセクション区分
enum ExamSection: String, CaseIterable, Identifiable {
    case dai1 = "第1問"
    case dai2_1 = "第2問⑴"
    case dai2_2a = "第2問⑵-A"
    case dai2_2b = "第2問⑵-B"

    var id: String { rawValue }

    /// 表示名
    var displayName: String { rawValue }

    /// セクションの説明
    var subtitle: String {
        switch self {
        case .dai1: return "CBT仕訳入力"
        case .dai2_1: return "T勘定空欄補充"
        case .dai2_2a: return "補助簿選択"
        case .dai2_2b: return "理論穴埋め"
        }
    }

    /// セクションのアイコン
    var iconName: String {
        switch self {
        case .dai1: return "pencil.and.list.clipboard"
        case .dai2_1: return "tablecells"
        case .dai2_2a: return "checklist"
        case .dai2_2b: return "text.book.closed"
        }
    }

    /// セクションのカラー
    var color: Color {
        switch self {
        case .dai1: return .appPrimary
        case .dai2_1: return .orange
        case .dai2_2a: return .purple
        case .dai2_2b: return .indigo
        }
    }
}
