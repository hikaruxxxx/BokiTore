import SwiftUI
import SwiftData

// MARK: - カスタムカラー
extension Color {
    /// アプリのプライマリカラー（青系）ライト/ダーク対応
    static let appPrimary = Color(light: Color(red: 0.2, green: 0.4, blue: 0.8),
                                   dark: Color(red: 0.4, green: 0.6, blue: 1.0))
    /// アプリのセカンダリカラー（緑 = 正解）ライト/ダーク対応
    static let appSecondary = Color(light: Color(red: 0.2, green: 0.7, blue: 0.4),
                                     dark: Color(red: 0.3, green: 0.85, blue: 0.5))
    /// エラーカラー（赤 = 不正解）ライト/ダーク対応
    static let appError = Color(light: Color(red: 0.9, green: 0.3, blue: 0.3),
                                 dark: Color(red: 1.0, green: 0.45, blue: 0.45))

    /// ライトモードとダークモードで異なる色を使うヘルパー
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - DateFormatter キャッシュ（生成コスト削減）
extension DateFormatter {
    /// yyyy/MM/dd 形式（日本語ロケール）
    static let jaSlashDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// M月d日 形式（日本語ロケール）
    static let jaShortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// 曜日1文字（月、火、水...）
    static let jaWeekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// yyyy-MM-dd 形式（日次制限チェック用）
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - Date拡張
extension Date {
    /// 日付を「yyyy/MM/dd」形式の文字列に変換
    var formattedDate: String {
        DateFormatter.jaSlashDate.string(from: self)
    }

    /// 日付を「M月d日」形式の文字列に変換
    var shortDate: String {
        DateFormatter.jaShortDate.string(from: self)
    }

    /// 今日の開始時刻（00:00:00）を取得
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 指定日数後の日付を取得（00:00:00に正規化）
    func daysFromNow(_ days: Int) -> Date {
        let date = Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
        return Calendar.current.startOfDay(for: date)
    }

    /// 明日の開始時刻を取得
    var tomorrow: Date {
        daysFromNow(1)
    }

    /// 短い曜日表示（月、火、水...）
    var shortWeekday: String {
        DateFormatter.jaWeekday.string(from: self)
    }
}

// MARK: - StudyStreak 連続日数計算（共通ロジック）
extension Array where Element == StudyStreak {
    /// 今日から遡って連続している学習日数を計算する
    /// - Parameter baseDate: 起点日（デフォルトは今日）
    /// - Returns: 連続日数
    /// - Note: 配列は date の降順にソート済みである必要がある
    func consecutiveDays(from baseDate: Date = .now) -> Int {
        guard !isEmpty else { return 0 }
        var count = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: baseDate)

        for streak in self {
            let streakDate = calendar.startOfDay(for: streak.date)
            if streakDate == checkDate {
                count += 1
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDate
            } else {
                break
            }
        }
        return count
    }
}
