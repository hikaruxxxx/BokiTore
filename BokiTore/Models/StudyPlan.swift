import Foundation
import SwiftData

/// 学習計画（Swift Data、1レコードのみ存在する想定）
@Model
class StudyPlan {
    /// 試験日（nilなら未設定）
    var examDate: Date?
    /// 1日の目標問題数
    var dailyGoal: Int
    /// 希望学習時間の時（0-23）
    var preferredHour: Int
    /// 希望学習時間の分（0-59）
    var preferredMinute: Int
    /// オンボーディング完了済みか
    var isOnboardingCompleted: Bool
    /// 作成日
    var createdAt: Date
    /// 通知スロット（JSON文字列で保存、SwiftDataの制約でCodable配列を直接保存できないため）
    var notificationSlotsJSON: String?
    /// 学習目的（"job_hunting" / "career_up" / "school_credits" / "hobby"）
    var studyPurpose: String = ""
    /// 興味のある資格（JSON配列文字列、notificationSlotsJSONと同パターン）
    var interestedCertsJSON: String?

    init(examDate: Date? = nil, dailyGoal: Int = 10, preferredHour: Int = 20,
         preferredMinute: Int = 0, isOnboardingCompleted: Bool = false,
         createdAt: Date = .now, notificationSlotsJSON: String? = nil,
         studyPurpose: String = "", interestedCertsJSON: String? = nil) {
        self.examDate = examDate
        self.dailyGoal = dailyGoal
        self.preferredHour = preferredHour
        self.preferredMinute = preferredMinute
        self.isOnboardingCompleted = isOnboardingCompleted
        self.createdAt = createdAt
        self.notificationSlotsJSON = notificationSlotsJSON
        self.studyPurpose = studyPurpose
        self.interestedCertsJSON = interestedCertsJSON
    }

    // MARK: - 通知スロットのヘルパー

    /// 通知スロットを取得する（JSON文字列からデコード）
    func getNotificationSlots() -> [NotificationSlot] {
        guard let json = notificationSlotsJSON,
              let data = json.data(using: .utf8) else {
            return NotificationSlot.defaults
        }
        do {
            return try JSONDecoder().decode([NotificationSlot].self, from: data)
        } catch {
            #if DEBUG
            print("通知スロットのデコードエラー: \(error)")
            #endif
            return NotificationSlot.defaults
        }
    }

    /// 通知スロットを保存する（JSON文字列にエンコード）
    func setNotificationSlots(_ slots: [NotificationSlot]) {
        do {
            let data = try JSONEncoder().encode(slots)
            notificationSlotsJSON = String(data: data, encoding: .utf8)
        } catch {
            #if DEBUG
            print("通知スロットのエンコードエラー: \(error)")
            #endif
        }
    }

    // MARK: - 興味資格のヘルパー

    /// 興味のある資格を取得する（JSON文字列からデコード）
    func getInterestedCerts() -> [String] {
        guard let json = interestedCertsJSON,
              let data = json.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            #if DEBUG
            print("興味資格のデコードエラー: \(error)")
            #endif
            return []
        }
    }

    /// 興味のある資格を保存する（JSON文字列にエンコード）
    func setInterestedCerts(_ certs: [String]) {
        do {
            let data = try JSONEncoder().encode(certs)
            interestedCertsJSON = String(data: data, encoding: .utf8)
        } catch {
            #if DEBUG
            print("興味資格のエンコードエラー: \(error)")
            #endif
        }
    }
}

/// 通知スロット（mikan式の複数時間帯設定）
struct NotificationSlot: Codable, Identifiable {
    let id: UUID
    var label: String       // "朝起きた時", "通勤・通学中" 等
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    var icon: String        // SFSymbol名

    /// デフォルトの通知スロット
    static let defaults: [NotificationSlot] = [
        NotificationSlot(id: UUID(), label: "朝起きた時", hour: 7, minute: 0, isEnabled: true, icon: "sun.max.fill"),
        NotificationSlot(id: UUID(), label: "通勤・通学中", hour: 8, minute: 30, isEnabled: false, icon: "bus.fill"),
        NotificationSlot(id: UUID(), label: "お昼休み", hour: 12, minute: 0, isEnabled: false, icon: "cup.and.saucer.fill"),
        NotificationSlot(id: UUID(), label: "寝る前", hour: 22, minute: 0, isEnabled: true, icon: "moon.fill")
    ]
}
