import Foundation
import FirebaseCore
import FirebaseAnalytics

/// Firebase Analyticsの管理
/// GoogleService-Info.plist が存在しない場合でもクラッシュしない設計
enum AnalyticsManager {

    // MARK: - 初期化

    /// Firebase SDKを安全に初期化する
    /// GoogleService-Info.plist が存在しない場合は何もしない
    static func configure() {
        // plistファイルの存在チェック（未配置でもクラッシュしない）
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            #if DEBUG
            print("⚠️ Analytics: GoogleService-Info.plist が見つかりません。Firebase Analyticsは無効です。")
            #endif
            return
        }

        // 既に初期化済みの場合はスキップ
        guard FirebaseApp.app() == nil else { return }

        FirebaseApp.configure()
        #if DEBUG
        print("✅ Analytics: Firebase を初期化しました")
        #endif
    }

    // MARK: - カスタムイベント

    /// 問題回答イベントを送信
    /// - Parameters:
    ///   - questionId: 問題ID（例: "q001"）
    ///   - category: カテゴリ名（例: "journalEntry"）
    ///   - subcategory: サブカテゴリ名（例: "sales"）
    ///   - isCorrect: 正解かどうか
    ///   - timeSpentSec: 回答にかかった秒数
    static func logQuestionAnswered(
        questionId: String,
        category: String,
        subcategory: String,
        isCorrect: Bool,
        timeSpentSec: Double
    ) {
        guard isConfigured else { return }
        Analytics.logEvent("question_answered", parameters: [
            "question_id": questionId,
            "category": category,
            "subcategory": subcategory,
            "is_correct": isCorrect,
            "time_spent_sec": Int(timeSpentSec)
        ])
        #if DEBUG
        print("📊 Analytics: question_answered — \(questionId), 正解:\(isCorrect)")
        #endif
    }

    /// セッション完了イベントを送信
    /// - Parameters:
    ///   - totalQuestions: 出題数
    ///   - correctCount: 正答数
    ///   - accuracy: 正答率（0.0〜1.0）
    ///   - sessionDurationSec: セッション時間（秒）
    static func logSessionCompleted(
        totalQuestions: Int,
        correctCount: Int,
        accuracy: Double,
        sessionDurationSec: Double
    ) {
        guard isConfigured else { return }
        Analytics.logEvent("session_completed", parameters: [
            "total_questions": totalQuestions,
            "correct_count": correctCount,
            "accuracy_percent": Int(accuracy * 100),
            "session_duration_sec": Int(sessionDurationSec)
        ])
        #if DEBUG
        print("📊 Analytics: session_completed — \(correctCount)/\(totalQuestions), \(Int(accuracy * 100))%")
        #endif
    }

    /// レベルアップ（マイルストーン達成）イベントを送信
    /// - Parameters:
    ///   - days: 達成日数
    ///   - rank: ランク名（例: "シルバー"）
    static func logLevelUp(days: Int, rank: String) {
        guard isConfigured else { return }
        Analytics.logEvent("level_up", parameters: [
            "milestone_days": days,
            "rank": rank
        ])
        #if DEBUG
        print("📊 Analytics: level_up — \(days)日, \(rank)")
        #endif
    }

    /// サブスクリプション購入ボタンタップイベントを送信
    /// - Parameter screenName: 画面名（例: "settings"）
    static func logSubscriptionTapped(screenName: String = "settings") {
        guard isConfigured else { return }
        Analytics.logEvent("subscription_tapped", parameters: [
            "screen_name": screenName
        ])
        #if DEBUG
        print("📊 Analytics: subscription_tapped — \(screenName)")
        #endif
    }

    /// アフィリエイトリンクタップイベントを送信
    /// - Parameters:
    ///   - promoId: プロモーションID
    ///   - sourceScreen: 表示元画面名
    static func logAffiliateTapped(promoId: String, sourceScreen: String) {
        guard isConfigured else { return }
        Analytics.logEvent("affiliate_tapped", parameters: [
            "promo_id": promoId,
            "source_screen": sourceScreen
        ])
        #if DEBUG
        print("📊 Analytics: affiliate_tapped — \(promoId), \(sourceScreen)")
        #endif
    }

    // MARK: - ユーザープロパティ

    /// ユーザープロパティを一括更新する
    /// - Parameters:
    ///   - examDate: 試験日（設定されている場合）
    ///   - streakDays: 連続学習日数
    ///   - totalAnswered: 累計回答数
    ///   - studyPurpose: 学習目的（"job_hunting"等、nilなら未設定）
    ///   - interestedCerts: 興味資格（カンマ区切り、nilなら未設定）
    static func updateUserProperties(
        examDate: String? = nil,
        streakDays: Int,
        totalAnswered: Int,
        studyPurpose: String? = nil,
        interestedCerts: String? = nil
    ) {
        guard isConfigured else { return }
        Analytics.setUserProperty(examDate, forName: "target_exam_date")
        Analytics.setUserProperty("\(streakDays)", forName: "study_streak_days")
        Analytics.setUserProperty("\(totalAnswered)", forName: "total_questions_answered")
        // 学習目的と興味資格（パーソナライズ分析用）
        Analytics.setUserProperty(studyPurpose, forName: "study_purpose")
        Analytics.setUserProperty(interestedCerts, forName: "interested_certs")
        #if DEBUG
        print("📊 Analytics: UserProperties更新 — streak:\(streakDays), total:\(totalAnswered), purpose:\(studyPurpose ?? "nil")")
        #endif
    }

    // MARK: - ヘルパー

    /// Firebase が初期化済みかどうか
    private static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }
}
