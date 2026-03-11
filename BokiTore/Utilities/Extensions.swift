import SwiftUI

// MARK: - カスタムカラー
extension Color {
    /// アプリのプライマリカラー（青系）
    static let appPrimary = Color(red: 0.2, green: 0.4, blue: 0.8)
    /// アプリのセカンダリカラー（緑 = 正解）
    static let appSecondary = Color(red: 0.2, green: 0.7, blue: 0.4)
    /// エラーカラー（赤 = 不正解）
    static let appError = Color(red: 0.9, green: 0.3, blue: 0.3)
}

// MARK: - Date拡張
extension Date {
    /// 日付を「yyyy/MM/dd」形式の文字列に変換
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }

    /// 日付を「M月d日」形式の文字列に変換
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }

    /// 今日の開始時刻（00:00:00）を取得
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 短い曜日表示（月、火、水...）
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
}
